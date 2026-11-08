"""Deterministic corpus recipes, not claims of gameplay coverage.

Implemented: enemy_cast_wait (the real-room setup of shadow_battle_smoke),
action_name_window (the same room's casts, witnessed by the exact text of the
three name windows they open) and enemy_kill (Ashley kills two hostile
enemies with her weapon, witnessed by the exact score changes). Routed calls
must actually occur for a run to pass.

The menu_* recipes (MenuScenario) are for the MENU overlays: from the save
room checkpoint, classic input only, they open the field menu and go through
its screens. Each is witnessed by the menu overlays the game loaded (the
disc reads in the game's log) and by the game state its screens changed.
"""
import os
import struct
from dataclasses import dataclass, replace


@dataclass(frozen=True)
class Scenario:
    name: str
    ticks: int = 600
    room: tuple = (48, 10)
    incomplete: str = ""

    def setup(self, game):
        if self.incomplete:
            raise NotImplementedError(self.incomplete)
        game.call("room_goto", zone=self.room[0], room=self.room[1],
                  enemies=True, scripts=False)
        for _ in range(80):
            game.run(20)
            if game.call("room_goto", action="status")["phase"] in (0, 4):
                break
        else:
            raise TimeoutError("room transition did not settle")
        state = game.state()
        if (state["zone"], state["room"]) != self.room:
            raise RuntimeError("wrong scenario room")

    def reset_witness(self, game):
        # Counters only: the charging skip's mode is the profile's (off in the
        # classic profile, on in the features one: corpus.py).
        game.call("skip_charging", reset=True)

    def witness(self, game):
        stats = game.call("skip_charging")
        ended = stats.get("ended", "")
        entries = [entry.split(":") for entry in ended.split()]
        casts = [entry for entry in entries if len(entry) >= 4
                 and int(entry[0]) != 0 and entry[2] == "1"]
        return {"ok": bool(casts), "ended": ended, "enemy_casts": casts}

    def play(self, game):
        # Recording includes neutral frames; no modern-menu/RPC play shortcuts.
        game.run(self.ticks)


@dataclass(frozen=True)
class NameWindowScenario(Scenario):
    """The enemies' casts in enemy_cast_wait's room over 1200 vsyncs, witnessed
    by the action name windows they open (vs_battle_displaySceneMessage, three
    calls; the charging tracker records each window's action and text,
    pc/src/charge_skip.inc). Exact: the three windows, in order, each with the
    text the original writes (the 0x04FB00F8 header, the action type's label
    and the action's name), the same in the classic and features profiles."""
    ticks: int = 1200
    EXPECTED = ("54:f800fb041c33282f2f9e8f910d282a2831283524372891",
                "95:f800fb041c33282f2f9e8f910d35242c31fa06162c312791",
                "75:f800fb041c33282f2f9e8f911c2c2f2831262891")

    def witness(self, game):
        stats = game.call("skip_charging")
        names = [entry for entry in stats.get("name", {}).get("names", "").split()
                 if not entry.startswith("-")]
        return {"ok": tuple(names) == self.EXPECTED, "name_windows": names, "expected": list(self.EXPECTED),
                "ended": stats.get("ended", "")}


def _pointer_size():
    return 8 if os.environ.get("ROOD_ARCH") == "64" else 4


@dataclass(frozen=True)
class KillScenario(Scenario):
    """Ashley kills two hostile enemies with her weapon, classic input only:
    _updateEnemyKills runs twice, on two branches, for odd enemy classes.

    Setup (before the mark, so in the pinned state): zone 9 room 18 with its
    enemies, the weapon drawn (Circle), 600 vsyncs for the nearer Zombie to
    come, 50 vsyncs of Right+Down, then every hostile enemy's HP set to 1
    (vs_battle_actor2.currentHP), so one hit kills. The farther Zombie (it
    idles out of reach) is moved to (340, 0, 702) beside the nearer one, the
    first hostile gets enemyClass 1 (Beast) and the second 3 (Phantom): odd
    classes, whose enemyKills entries sit at 2 mod 4 (the psx.at alignment
    case). The streak is set to class 1, count 99, and the streak score to 0.
    Play (recorded): four times Circle (the targeting sphere), Circle (the
    body part list), Circle (attack) and 350 vsyncs. The moved Zombie dies
    first (class 1: the same class as the streak, the count 99 -> 100), then
    the other (class 3: a new class, the count back to 0).
    Witness, exact: enemyKills[1] and [3] up by one and no other entry
    changed; the streak class 3, count 0; the streak score 0 + 154 + 154*100/2
    + 154*1/2 (the weapon streak) + 0 (chain) = 7931, then + 133 + 0 + 133*2/2
    = 8197; both enemies' kill flags set."""
    room: tuple = (9, 18)
    ticks: int = 1700
    HP = 0x18  # vs_battle_actor2 currentHP
    CLASS = 55  # vs_battle_actor2 enemyClass (bits 0-2)
    STATS = 0x3C  # vs_battle_actor unk3C (stats)
    SUBTYPE = 0x1A  # vs_battle_actor subType
    ALLEGIANCE = 0x1C  # vs_battle_actor unk1C: 4 hostile
    POSITION = 28  # D_800F4538_t unk0.position
    ENEMY_KILLS = 4  # vs_main_scoredata_t enemyKills[6]
    KILL_FLAGS = 0x9C  # vs_main_scoredata_t enemyKillFlags[26]
    STREAK_SCORE = 0x104  # vs_main_scoredata_t streakScore
    STREAK = 0x10C  # killStreakEnemyClass, killStreakEnemyCount
    CLASSES = (1, 3)
    EXPECTED_SCORE = 8197

    def setup(self, game):
        super().setup(game)
        game.press("circle", 3, 30)
        game.run(600)
        game.hold(["right", "down"], 50)
        from rood_rpc import symbols
        sym, width = symbols(), _pointer_size()
        hostiles = []
        for slot in range(1, 16):
            actor = int.from_bytes(game.read(sym["vs_battle_actors"] + slot * width, width), "little")
            if not actor:
                continue
            stats = int.from_bytes(game.read(actor + self.STATS, 4), "little")
            hostile = struct.unpack("<H", game.read(actor + self.ALLEGIANCE, 2))[0] == 4
            if stats and hostile:
                game.write(stats + self.HP, struct.pack("<h", 1))
                hostiles.append((slot, actor, stats))
        if len(hostiles) != 2:
            raise RuntimeError(f"expected two hostile enemies, found {len(hostiles)}")
        for (slot, actor, stats), enemy_class in zip(hostiles, self.CLASSES):
            byte = game.read(stats + self.CLASS, 1)[0]
            game.write(stats + self.CLASS, bytes([(byte & ~7) | enemy_class]))
        moved = int.from_bytes(game.read(sym["D_800F4538"] + hostiles[0][0] * width, width), "little")
        game.write(moved + self.POSITION, struct.pack("<3h", 340, 0, 702))
        score = sym["vs_main_scoredata"]
        game.write(score + self.STREAK, bytes([self.CLASSES[0], 99]))
        game.write(score + self.STREAK_SCORE, struct.pack("<I", 0))
        object.__setattr__(self, "_subtypes", [struct.unpack("<H", game.read(actor + self.SUBTYPE, 2))[0]
                                               for _, actor, _ in hostiles])

    def score(self, game):
        from rood_rpc import symbols
        data = game.read(symbols()["vs_main_scoredata"], 0x110)
        return {"kills": list(struct.unpack_from("<6H", data, self.ENEMY_KILLS)),
                "flags": list(struct.unpack_from("<26I", data, self.KILL_FLAGS)),
                "streak": list(data[self.STREAK:self.STREAK + 2]),
                "streak_score": struct.unpack_from("<I", data, self.STREAK_SCORE)[0]}

    def reset_witness(self, game):
        object.__setattr__(self, "_baseline", self.score(game))

    def witness(self, game):
        before, after = getattr(self, "_baseline", None), self.score(game)
        if before is None:
            return {"ok": False, "reason": "no baseline"}
        expected = list(before["kills"])
        for enemy_class in self.CLASSES:
            expected[enemy_class] += 1
        flags = all(after["flags"][t // 32] >> (t % 32) & 1 for t in getattr(self, "_subtypes", []) if t < 256)
        ok = (after["kills"] == expected and after["streak"] == [self.CLASSES[1], 0]
              and after["streak_score"] == self.EXPECTED_SCORE and flags)
        return {"ok": ok, "enemy_kills": [before["kills"], after["kills"]], "expected_kills": expected,
                "streak": after["streak"], "streak_score": after["streak_score"],
                "expected_streak_score": self.EXPECTED_SCORE, "kill_flags_set": flags}

    def play(self, game):
        used = 0
        for _ in range(4):
            for _ in range(3):
                game.press("circle", 3, 20)
                used += 23
            game.run(350)
            used += 350
        game.run(self.ticks - used)



# The MENU overlays' disc sectors (the retail disc: lbas.h, VS_<name>_LBA), and
# the menu each is (pc/tests/diff/CORPUS.md).
MENU_OVERLAYS = {85000: "MAINMENU", 85030: "MENU0", 85039: "MENU1", 85043: "MENU2",
                 85049: "MENU3", 85063: "MENU4", 85075: "MENU5", 85126: "MENU7",
                 85215: "MENU8", 85222: "MENU9", 85239: "MENUB", 85255: "MENUC",
                 85285: "MENUD", 85300: "MENUE", 85306: "MENUF"}
CLOSED = 0x3F  # vs_battle_menuState.currentMenu with no menu open (the top level is 0)
PRESS_VSYNCS = 3  # a button held three vsyncs is one press (pc/tools/rood_rpc.py press)


def press(button, settle=30):
    return ("press", button, settle)


def wait(vsyncs):
    return ("wait", vsyncs)


def chord(hold, button, settle=60):
    """`button` pressed while `hold` is already down (the game reads the
    previous frame's buttons: L2 + a button is a shortcut)."""
    return ("chord", hold, button, settle)


def vsyncs_of(steps):
    return sum({"press": lambda s: PRESS_VSYNCS + s[2], "wait": lambda s: s[1],
                "chord": lambda s: 12 + s[3]}[step[0]](step) for step in steps)


def disc_loads(game, start):
    """The MENU overlays the game loaded since byte `start` of its log
    (boot_runtime.c pc_disc_read: "[disc] LBA <sector>, ..."), in order."""
    with open(game.log, "rb") as stream:
        stream.seek(start)
        lines = stream.read().decode("ascii", "replace").splitlines()
    loads = []
    for line in lines:
        if line.startswith("[disc] LBA "):
            lba = int(line.split()[2].rstrip(","))
            if lba in MENU_OVERLAYS:
                loads.append(MENU_OVERLAYS[lba])
    return loads


def guest(game, name, length):
    from rood_rpc import symbols
    return game.read(symbols()[name], length)


@dataclass(frozen=True)
class MenuScenario(Scenario):
    """Classic-input play in the field menu from the save room checkpoint
    (zone 9 room 17, Ashley idle, the card a copy of the pinned one): the
    steps open the field menu (Triangle), go through the screens named by
    the recipe and leave state the witness reads exactly.

    No setup before the mark beyond checking the room: the checkpoint's state
    is the recipe's. The witness is exact in two parts: `loads`, the MENU
    overlays the game read from the disc during the play (in order: the
    witness is the game's own overlay loader running), and the entries of
    dump() the screens changed, compared with `expected`. The change a recipe
    makes and undoes (equipment, an option) is witnessed by ending on the
    changed value, as the end state is all a replay keeps."""
    room: tuple = (9, 17)
    steps: tuple = ()
    loads: tuple = ()  # the MENU overlays the play loads, in order
    fields: tuple = ()  # the dump() entries the screens change
    expected: tuple = ()  # (name, value) pairs for `fields`

    def __post_init__(self):
        object.__setattr__(self, "ticks", vsyncs_of(self.steps))

    def setup(self, game):
        state = game.state()
        if (state["zone"], state["room"]) != self.room:
            raise RuntimeError("wrong scenario room")
        menu = game.u32("vs_battle_menuState") & 0xFF
        if menu != CLOSED:
            raise RuntimeError(f"the field menu is not closed at the mark ({menu:#x})")

    def reset_witness(self, game):
        import os
        object.__setattr__(self, "_log_start", os.path.getsize(game.log))

    def state(self, game):
        data = dump(game)
        return {name: data[name] for name in self.fields}

    def witness(self, game):
        start = getattr(self, "_log_start", None)
        if start is None:
            return {"ok": False, "reason": "no baseline"}
        loads, state = disc_loads(game, start), self.state(game)
        expected = {name: value for name, value in self.expected}
        ok = tuple(loads) == self.loads and state == expected
        return {"ok": ok, "overlay_loads": loads, "expected_loads": list(self.loads),
                "state": state, "expected_state": expected}

    def play(self, game):
        used = 0
        for step in self.steps:
            if step[0] == "press":
                game.press(step[1], PRESS_VSYNCS, step[2])
            elif step[0] == "wait":
                game.run(step[1])
            else:
                game.call("input", buttons=[step[1]], vsyncs=40)
                game.run(8)
                game.call("input", buttons=[step[1], step[2]], vsyncs=4)
                game.run(4 + step[3])
            used += vsyncs_of([step])
        if used != self.ticks:
            raise RuntimeError("the recipe's steps do not add up")


OPEN = (press("triangle", 80),)  # the field menu: the cursor is on Battle Abilities
# Items is one down from there, Status two, Map three, Data four, Options
# five, Score six, Quick Manual seven (the Magic and Break Arts rows are
# absent in this save).


def dump(game):
    """What the recipes' screens can change, for finding a recipe's witness."""
    inventory = guest(game, "vs_main_inventory", 0x1000)
    settings = guest(game, "vs_main_settings", 0x20)
    return {"hp": game.state()["hp"], "menu": list(guest(game, "vs_battle_menuState", 4)),
            "submenus": list(guest(game, "vs_battle_submenuStates", 8)),
            "settings": settings.hex(), "option_flags": settings[0],
            "mapped_abilities": list(settings[12:20]),
            "weapons": [inventory[i * 0x20 + 3] for i in range(8)],
            "shields": [inventory[0x100 + i * 0x30 + 1] for i in range(8)],
            "misc": [list(inventory[0xE00 + i * 4:0xE00 + i * 4 + 4]) for i in range(4)]}


SCENARIOS = {"enemy_cast_wait": Scenario("enemy_cast_wait"),
             "action_name_window": NameWindowScenario("action_name_window"),
             "enemy_kill": KillScenario("enemy_kill"),
             "menu_items_use": MenuScenario("menu_items_use", steps=(
                 chord("l2", "up", 90), press("circle", 60), press("circle", 150), wait(300))),
             "menu_equip_setup": MenuScenario("menu_equip_setup", steps=OPEN + (
                 press("down"), press("circle", 100), press("circle", 50), press("circle", 50),
                 press("down", 25), press("circle", 60), press("down", 25), press("circle", 250),
                 press("circle", 60), press("down", 25), press("circle", 250),
                 press("circle", 60), press("down", 25), press("circle", 250),
                 press("cross", 60), press("down", 25), press("circle", 100),
                 press("down", 25), press("circle", 60), press("cross", 50), press("cross", 60),
                 press("cross", 60), press("cross", 60))),
             "menu_abilities_status": MenuScenario("menu_abilities_status", steps=OPEN + (
                 press("circle", 100), press("circle", 60), press("circle", 30), press("down", 20),
                 press("triangle", 30), press("cross", 50), press("down", 20), press("circle", 60),
                 press("circle", 30), press("down", 20), press("square", 30), press("cross", 50),
                 press("cross", 60), press("down", 20), press("down", 20), press("circle", 100),
                 press("r1", 40), press("r1", 40), press("down", 20), press("circle", 40),
                 press("cross", 40), press("cross", 60), press("cross", 60), press("cross", 60))),
             "menu_map_score_manual": MenuScenario("menu_map_score_manual", steps=OPEN + (
                 press("down", 50), press("down", 50), press("down", 50), press("circle", 143),
                 press("right", 50), press("r1", 50), press("down", 50), press("l1", 50),
                 press("cross", 160), press("down", 50), press("down", 50),
                 press("down", 50), press("circle", 143), press("cross", 80), press("down", 50),
                 press("circle", 123), press("down", 50), press("circle", 123), press("cross", 80),
                 press("cross", 80), press("cross", 80))),
             "menu_options_data": MenuScenario("menu_options_data", steps=OPEN + (
                 press("down", 50), press("down", 50), press("down", 50), press("down", 50),
                 press("down", 50), press("circle", 120), press("down", 35), press("circle", 60),
                 press("down", 35), press("circle", 60), press("cross", 60), press("up", 45),
                 press("circle", 120), press("circle", 80), press("circle", 220), press("cross", 80),
                 press("cross", 80), press("down", 40), press("circle", 80), press("circle", 220))),
             }
# Each menu recipe's witness, observed in the original and exact: the overlays it
# loads, the state its screens leave (the field menu closed is currentMenu 0x3F).
CLOSED_MENU = ("menu", [CLOSED, 0, 0, 0])
MENU_WITNESS = {
    # L2 + Up: the MISC list (MAINMENU only, loaded again for the target); Cure Root
    # (12 -> 11) used on Ashley (157 + 50 + a point of regeneration)
    "menu_items_use": (("MAINMENU", "MAINMENU"), ("hp", "misc", "menu"),
                       (("hp", 208), ("misc", [[67, 1, 11, 1], [75, 1, 13, 2], [83, 1, 20, 3], [84, 1, 5, 4]]),
                        CLOSED_MENU)),
    # Items > Equip > Shield: Pelta Shield on, Buckler back on, Pelta Shield on; Setup (the
    # workshop-only caution)
    "menu_equip_setup": (("MAINMENU", "MENU3", "MENUC", "MENU3"), ("weapons", "shields", "menu"),
                         (("weapons", [1, 0, 0, 0, 0, 0, 0, 0]), ("shields", [0, 1, 0, 0, 0, 0, 0, 0]),
                          CLOSED_MENU)),
    # Battle Abilities: chain abilities 0x16 on Circle, 0x17 on Triangle, defense abilities 0x28
    # on Circle, 0x2B on Square; Status (Ashley, the dummy and back)
    "menu_abilities_status": (("MAINMENU", "MENU2", "MENU4"), ("mapped_abilities", "menu"),
                              (("mapped_abilities", [0x16, 0x17, 0, 0, 0x28, 0, 0x2B, 0]), CLOSED_MENU)),
    # Map (pan, the next area), Score, Quick Manual
    "menu_map_score_manual": (("MAINMENU", "MENU5", "MENU9", "MENUE"), ("hp", "menu"),
                              (("hp", 157), CLOSED_MENU)),
    # Options (a setting changed: the first byte of vs_main_settings 0x30 -> 0x10), then
    # Data > Save > slot 1's files, cancelled, Data > Load > slot 1's files (substate 0x0A)
    "menu_options_data": (("MAINMENU", "MENU8", "MENU7"), ("option_flags", "menu", "submenus"),
                          (("option_flags", 0x10), ("menu", [0x47, 0, 0, 0]),
                           ("submenus", [6, 0, 0, 0, 0, 0, 0, 0x0A]))),
}
for _name, (_loads, _fields, _expected) in MENU_WITNESS.items():
    SCENARIOS[_name] = replace(SCENARIOS[_name], loads=_loads, fields=_fields, expected=_expected)
for _name in ("spell", "item", "attack", "chain", "cancel", "miss", "defence",
              "break_art", "status", "multiple_targets", "roaming",
              "doors", "events", "cutscene", "menus_hud", "effects", "traps",
              "loot", "save_point", "actor_transform"):
    SCENARIOS[_name] = Scenario(_name, incomplete="classic-input recipe and semantic witness not implemented")
IMPLEMENTED = {name for name, scenario in SCENARIOS.items() if not scenario.incomplete}


def select(names=None):
    """Default means the whole required corpus, including explicit gaps."""
    return [SCENARIOS[name] for name in (names or SCENARIOS)]
