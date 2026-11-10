#!/usr/bin/env python3
"""Does a change alter the game? The same fight on two builds, frame by frame.

    python3 pc/tools/build_compare.py OLD_BINARY [NEW_BINARY] [--card CARD] [--seconds 30]

Every step the named fields of every actor (RPC battle_state: its record, stats, object and AI state) are
compared too, which shows what an off-screen actor does. Afterwards every enemy is defeated (its HP written to 0) and the loot the game builds
is compared too: how many drop nodes, each one's actor id and item bytes.

Runs are deterministic (no wall clock in game logic, no input), so two builds of
the same behaviour draw the same frames. A room with enemies is entered from the
save room checkpoint and left to play: the enemies walk, attack and cast. Every
quarter second the frame's hash is taken and, at the end, what was cast. NEW_BINARY
defaults to this tree's build. OLD against OLD runs first as the control: if that
differs, the comparison proves nothing and the tool says so. Exit 0 when the frames
match, and the sound: the room's recorded mix (this room, then zone 15 room 0 with its script) must be byte for byte the same
(--audio off skips it; on a mismatch the first differing time is printed). Covers this fight and this sound only, not every screen or effect.

    python3 pc/tools/build_compare.py OLD_BINARY --casts [spells,arts] [--cast-limit N]

The wider lane: instead of the fight, Ashley casts every spell of the four schools (and
the equipped category's Break Arts) through the menus, as tests/charge_skip_soak.py does,
and the display is hashed every few vsyncs through each action. Old, old again (the
control) and new are compared action by action. Where the new build records them
(RPC effect_sites), the effect polygon call sites that ran are mapped to plugin
functions and counted against all of the build's (the coverage the frames cover).
Slow (several minutes); its actions are the spells' effect plugins, not every one.

    python3 pc/tools/build_compare.py OLD_BINARY --menus [ending,menuf] [--menu-sample N] [--claims off] [--aspect 16:9] [--new-env K=V]

The menus' lane: the screens the classic UI draws, reached by the routes classic_parity.py tours them by (the
save room's game, the classic look: the shipped plugins on, so rood.classic's claims draw what they claim;
--claims off leaves the game's own drawing), with the display hashed every N vsyncs (default 10) through
everything each route does. Old, old again (the control) and new are compared route by route. The routes are
SCENES below: a new screen's route is one function there, or one of classic_parity.py's tours wrapped as the others are. Routes:
mainmenu, manual, levelled, items, magic, arts, abilities, status, score, map, data (MENU7's SAVE and LOAD file menus), setup, loot,
storage, ending, menuf, dialogue (the talk bubble's every shape: first_bubble), title (its menu and its file menu's copy) and gameover
(MENU7's game over LOAD).
"""
import argparse
import contextlib
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
ROOM = tuple(int(n) for n in os.environ.get("BUILD_COMPARE_ROOM", "48,10").split(","))  # (zone, room) of the fight; another room has other enemies and abilities


ROOM_ENEMIES = range(2, 10)  # vs_battle_actors slots of the room's enemies
STATS_HP = 0x18  # vs_battle_actor2.currentHP (the stats pointer is read by the build's exported offset)
LOOT_BYTES = 0x220  # vs_battle_loot; a drop node is: next (the pointer's width), int actorId, the loot


def loot(g, width):
    """Defeat the room's enemies and read the drop list: [(actor id, item bytes hash)]."""
    from rood_rpc import symbols
    sym = symbols()
    pointers = g.read(sym["vs_battle_actors"], 16 * 8)
    for slot in ROOM_ENEMIES:
        actor = int.from_bytes(pointers[slot * 8:slot * 8 + 8], "little")
        stats = g.actor_stats(actor) if actor else 0
        if stats:
            g.write(stats + STATS_HP, (0).to_bytes(2, "little"))
    head = lambda: int.from_bytes(g.read(sym["_lootListHead"], 8), "little") & ((1 << 8 * width) - 1)
    for _ in range(40):
        g.run(15)
        if head():
            break
    g.run(60)
    drops, node = [], head()
    while node and len(drops) < 64:
        raw = g.read(node, width + 4 + LOOT_BYTES)
        drops.append([int.from_bytes(raw[width:width + 4], "little"), hashlib.sha256(raw[width + 4:]).hexdigest()[:16]])
        node = int.from_bytes(raw[:width], "little")
    return drops


def cover(binary):
    """BUILD_COMPARE_COVER=<log>: this tree's own build runs under gdb (pc/tools/line_coverage.py), the lines it reaches
    appended to the log; ROOD_BINARY is the wrapper, ROOD_SYMBOLS stays the binary."""
    log = os.environ.get("BUILD_COMPARE_COVER")
    work = ROOT / "pc/build/line_coverage"
    if log and pathlib.Path(binary).resolve() == pathlib.Path(os.environ.get("BUILD_COMPARE_COVER_BINARY") or ROOT / "pc/build/boot64/rood_battle_probe").resolve() and (work / "wrap").exists():
        os.environ.update(ROOD_BINARY=str(work / "wrap"), COV_REAL=str(pathlib.Path(binary).resolve()), COV_PROBE=str(work / "probe.py"),
                          COV_TARGETS=str(work / "targets.txt"), COV_LOG=log)


def start(card, out, name):
    """A game in the fight's room, scripts off, the settings the comparison needs."""
    from checkpoints import launch_at
    g = launch_at("save_room", card=card, fast=True, log=out / f"{name}.log", extra_env={
        "ROOD_GI": "0", "ROOD_INTERPOLATE": "0", "ROOD_SETTINGS": str(out / "settings.cfg"), "ROOD_AUDIO": "none",
        "ROOD_WINDOW": "960x720", "ROOD_LIGHTS": str(out / "lights"), "ROOD_PREFABS": str(out / "prefabs")})
    g.call("graphics", interpolate=False)
    g.call("room_goto", zone=ROOM[0], room=ROOM[1], enemies=True, scripts=False)
    for _ in range(80):
        g.run(20)
        if g.call("room_goto", action="status")["phase"] in (0, 4):
            break
    return g


def play(binary, seconds, card, out, width):
    """In a process of its own (ROOD_BINARY is read at import): the hashes, the casts and the drops, as JSON on stdout."""
    os.environ.update(ROOD_BINARY=binary, ROOD_SYMBOLS=binary, ROOD_HEADLESS="egl", ROOD_RENDERER="vulkan", ROOD_ARCH="64", ROOD_TEST_SNAPSHOTS="0")
    sys.path[:0] = [str(ROOT / "pc/tools"), str(ROOT / "pc/tests")]
    cover(binary)
    out = pathlib.Path(out)
    (out / "settings.cfg").write_text("qol_skip_charging 0\nui_menus 0\n")
    g = start(card, out, "fight")
    try:
        g.call("skip_charging", reset=True)
        frames, states = [], []
        for _ in range(seconds * 4):
            g.run(15)
            shot = out / "frame.ppm"
            g.screenshot(str(shot))
            frames.append(hashlib.sha256(shot.read_bytes()).hexdigest()[:16])
            try:  # a build older than the RPC has none: the comparison says so
                states.append(g.call("battle_state"))
            except Exception:
                states.append(None)
        ended = g.call("skip_charging").get("ended", "")
    finally:
        g.close()
    # A second game: the enemies defeated while idle (one mid-cast does not die at once).
    g = start(card, out, "loot")
    try:
        drops = loot(g, width)
    finally:
        g.close()
    casts = [e for e in (entry.split(":") for entry in ended.split()) if len(e) >= 4 and int(e[0]) != 0 and e[2] == "1"]
    print("RESULT" + json.dumps({"frames": frames, "casts": casts, "drops": drops, "states": states}))


SCHOOLS = (("warlock", 18), ("shaman", 6), ("sorcerer", 18), ("enchanter", 8))
SAMPLE = int(os.environ.get("ROOD_CAST_SAMPLE", 6))  # vsyncs between display hashes in an action (to narrow a difference: 1)
CAST_ONLY = [int(i) for i in os.environ.get("ROOD_CAST_ONLY", "").split(",") if i]  # --casts: only these spell ids


def play_casts(binary, card, out, kinds, limit):
    """Every spell (and art) cast with its holds skipped, the display hashed through each: {action: [hashes]}, and
    the effect polygon call sites the build recorded (empty for a build without the RPC)."""
    os.environ.update(ROOD_BINARY=binary, ROOD_SYMBOLS=os.environ.get("ROOD_CAST_SYMBOLS", binary), ROOD_HEADLESS="egl",
                      ROOD_RENDERER="vulkan", ROOD_ARCH="64", ROOD_TEST_SNAPSHOTS="0")
    sys.path[:0] = [str(ROOT / "pc/tools"), str(ROOT / "pc/tests")]
    cover(binary)
    from checkpoints import launch_at
    import skip_charging_smoke as smoke
    import charge_skip_soak as soak
    out = pathlib.Path(out)
    (out / "prefabs").mkdir()
    (out / "lighting").mkdir()
    env = {"ROOD_WINDOW": "960x720", "ROOD_LIGHTS": str(out / "lights"), "ROOD_PREFABS": str(out / "prefabs"),
           "ROOD_LIGHTING": str(out / "lighting"), "ROOD_GI": "0", "ROOD_INTERPOLATE": "0", "ROOD_AUDIO": "none", "ROOD_OUT": str(out)}
    os.environ.pop("ROOD_SETTINGS", None)
    card_copy = out / "card1.mcd"
    card_copy.write_bytes(pathlib.Path(card).read_bytes())
    socket = f"/tmp/rood-bcompare-{os.getpid()}.sock"
    snap = out / "room.snap"
    g = launch_at("save_room", card=card_copy, fast=True, log=out / "boot.log", extra_env=env, socket_path=socket)
    try:
        g.call("room_goto", zone=smoke.ROOM[0], room=smoke.ROOM[1], enemies=True, scripts=False)
        for _ in range(80):
            g.run(20)
            if g.call("room_goto", action="status")["phase"] in (0, 4):
                break
        g.run(smoke.APPROACH)
        g.call("snapshot", action="save", path=str(snap))
    finally:
        g.close()

    class Cast(soak.Soak):
        def cast(self, what):
            """soak.Soak.run_action, hashing the display every SAMPLE vsyncs from the target's confirmation."""
            g = self.g
            g.call("skip_charging", reset=True)
            g.press("circle", vsyncs=3, settle=1)
            try:
                self.wait(lambda: self.mode_now() == (2, smoke.CLOSED), 120, "")
            except TimeoutError:
                return None
            g.run(10)
            for _ in range(6):
                g.call("input", buttons=["circle"], vsyncs=3)
                g.run(4)
                if self.camera_mode() not in (1, 2, 3):
                    break
                g.run(30)
            if self.camera_mode() in (1, 2, 3):
                for _ in range(4):
                    g.press("cross", vsyncs=3, settle=10)
                    if self.mode_now()[0] != 2:
                        break
                return None
            hashes = []
            self.last_states = []
            for i in range(soak.WATCHDOG // SAMPLE):
                g.run(SAMPLE)
                shot = out / "frame.ppm"
                g.screenshot(str(shot))
                hashes.append(hashlib.sha256(shot.read_bytes()).hexdigest()[:12])
                keep = os.environ.get("BUILD_COMPARE_KEEP")  # a directory: the action's frames, by process and sample
                if keep:
                    pathlib.Path(keep).mkdir(parents=True, exist_ok=True)
                    (pathlib.Path(keep) / f"cast-{os.getpid()}-{len(hashes) - 1:04d}.ppm").write_bytes(shot.read_bytes())
                try:
                    state = g.call("battle_state")
                    if os.environ.get("ROOD_CAST_VIEW"):  # the scene's view record (vs_view; the scratchpad at 0x1F800010 before it)
                        symbols = sys.modules["rood_rpc"].symbols()
                        state["view"] = g.read(symbols.get("vs_view", 0x1F800010), 0x58).hex()
                    self.last_states.append(state)
                except Exception:
                    self.last_states.append(None)
                if i > 2 and self.mode_now()[0] == 1:
                    break
            g.run(4)
            return hashes

    r = Cast("casts", snap, card_copy, env, out, socket, fast=True)
    g, sym = r.g, r.sym
    actions, sites, peak, states = {}, [], 0, {}
    try:
        g.call("ui_menu", modern=True)
        g.call("skip_charging", mode="skip", who="all", name=smoke.NAME_SECONDS)
        g.write(sym["vs_main_settings"] + smoke.INFORMATION, b"\x01")
        flags = g.read(sym["vs_main_settings"] + soak.MENU_FLAGS, 1)[0]
        g.write(sym["vs_main_settings"] + soak.MENU_FLAGS, bytes([flags | 1]))
        for name, size in SCHOOLS:
            for i in g.read(sym[f"vs_battle_{name}SpellIds"], size):
                a = sym["vs_main_actions"] + i * smoke.ACTION + smoke.ACTION_UNLOCKED
                g.write(a, bytes([g.read(a, 1)[0] | 0x80]))
        g.run(4)
        try:
            g.call("effect_sites", on=True, reset=True)
        except Exception:
            pass
        count = 0
        for name, size in (SCHOOLS if "spells" in kinds else ()):
            r.refill()
            r.shell("magick")
            for _ in range(6):
                if r.ui()["magick"].get("sub") == name:
                    break
                g.press("r2", vsyncs=3, settle=4)
            spells = next(s["spells"] for s in r.ui()["magick"]["schools"] if s.get("id") == name)
            for row, spell in enumerate(spells):
                if limit and count >= limit:
                    break
                if CAST_ONLY and spell["id"] not in CAST_ONLY:
                    continue
                r.refill()
                r.shell("magick")
                for _ in range(6):
                    if r.ui()["magick"].get("sub") == name:
                        break
                    g.press("r2", vsyncs=3, settle=4)
                for _ in range(24):
                    c = r.ui()["magick"]["cursor"]
                    if c == row:
                        break
                    g.press("down" if c < row else "up", vsyncs=3, settle=4)
                hashes = r.cast(f"spell {spell['id']}")
                actions[f"spell {name} {spell['id']}"] = hashes
                states[f"spell {name} {spell['id']}"] = r.last_states if hashes else None
                count += hashes is not None
        if "arts" in kinds:
            art0, _ = r.learn_art()
            for k in range(4):
                a = sym["vs_main_actions"] + (art0 + k) * smoke.ACTION + smoke.ACTION_UNLOCKED
                g.write(a, bytes([g.read(a, 1)[0] | 0x80]))
            r.shell("abilities")
            cat = r.ab()["equipped_category"]
            g.write(sym["vs_main_artsStatus"] + smoke.ARTS_LEARNED + cat % 10, bytes([4]))
            r.shell_close()
            for k in range(4):
                r.refill()
                r.art_menu(art0)
                for _ in range(6):
                    if r.ab()["art"] == k:
                        break
                    g.press("down", vsyncs=3, settle=4)
                actions[f"art {art0 + k}"] = r.cast(f"art {art0 + k}")
                states[f"art {art0 + k}"] = r.last_states
        try:
            reply = g.call("effect_sites")
            sites, peak = reply["sites"], reply["peak_items"]
        except Exception:
            sites, peak = [], 0
    finally:
        r.close()
    print("RESULT" + json.dumps({"actions": actions, "states": states, "sites": sites, "peak": peak}))


MENU_SAMPLE = 10  # vsyncs between display hashes in a menu route


def hashed(g, out, sample, hashes):
    """g.run in steps that end on multiples of `sample` vsyncs, the display hashed at each: the hashes are the
    route's, whatever the route waits on (classic_parity.py's tours run a vsync at a time and press buttons)."""
    run, shot, state = g.run, out / "frame.ppm", {"t": 0}

    def stepping(vsyncs):
        left = vsyncs
        while left > 0:
            step = min(left, sample - state["t"] % sample)
            run(step)
            state["t"] += step
            left -= step
            if state["t"] % sample == 0:
                g.screenshot(str(shot))
                hashes.append(hashlib.sha256(shot.read_bytes()).hexdigest()[:12])
                keep = os.environ.get("BUILD_COMPARE_KEEP")  # (a directory: every sampled frame kept, for looking at a difference)
                if keep:
                    pathlib.Path(keep).mkdir(parents=True, exist_ok=True)
                    (pathlib.Path(keep) / f"{os.getpid()}-{len(hashes) - 1:04d}.ppm").write_bytes(shot.read_bytes())
    g.run = stepping


def scene_ending(g, cp, symbols):
    """The credits skipped, MISSION COMPLETE coming in, at rest and left with Cross (its fade-out)."""
    from ending_smoke import CREDITS_DONE, RANK_SCREEN_STEP
    step = lambda: int.from_bytes(g.read(RANK_SCREEN_STEP, 4), "little")
    g.call("ending")
    g.run(1200)
    g.press("start", vsyncs=4, settle=200)
    g.until(lambda: step() > 0x120, step=30, guard=1800, what="the MISSION COMPLETE screen")
    g.run(120)
    g.press("cross", vsyncs=3, settle=240)


def scene_mainmenu(g, cp, symbols):
    """The menu opened from the field, each top command entered, moved through and left."""
    g.press("triangle", vsyncs=3, settle=60)
    for _ in range(9):
        g.press("circle", vsyncs=3, settle=60)
        for button in ("down", "down", "up", "right", "left"):
            g.press(button, vsyncs=3, settle=12)
        g.press("cross", vsyncs=3, settle=40)
        g.press("down", vsyncs=3, settle=12)
    g.press("cross", vsyncs=3, settle=60)


def scene_manual(g, cp, symbols):
    """The Quick Manual (MENUE): the list, a topic's pages, back (classic_parity.py's own opening)."""
    from menu_nav import top_command
    flags = int.from_bytes(g.read(symbols["vs_main_settings"] + 2, 2), "little")
    g.write(symbols["vs_main_settings"] + 2, (flags | 1 << cp.MANUAL_COMMAND).to_bytes(2, "little"))
    g.press("triangle", vsyncs=3, settle=30)
    top_command(g, symbols, cp.MANUAL_COMMAND)
    g.press("circle", vsyncs=2, settle=2)
    g.run(400)  # (a fixed wait: the manual's own state is read by symbol, and not by every build's)
    for button in ("down", "down", "up", "circle"):
        g.press(button, vsyncs=3, settle=40)
    for button in ("down", "down", "up", "up"):
        g.press(button, vsyncs=3, settle=20)
    for _ in range(2):
        g.press("cross", vsyncs=3, settle=40)


def scene_levelled(g, cp, symbols):
    """The original Magic menu's LV picker (MENU0 84.c), a levelled Warlock spell with LV1 and LV2 learned: to LV1, to LV2,
    then LV1 again (menu0_levelled_smoke.py's route: its setup and its walk to the picker, the pad sequence the same)."""
    import struct
    import menu0_levelled_smoke as m
    s = m.Session.__new__(m.Session)
    s.g, s.sym, s.out, s.shots = g, symbols, pathlib.Path("."), False
    g.call("ui_menu", modern=False)
    f = symbols["vs_main_settings"] + m.MENU_FLAGS
    g.write(f, struct.pack("<H", struct.unpack("<H", g.read(f, 2))[0] | 1))
    for level in range(4):
        s.set_learned(m.EXPLOSION + level, level < 2)
    g.run(2)
    spells = [i for i in g.read(symbols["vs_battle_warlockSpellIds"], 18) if s.learned(i)]
    s.fill_mp(s.cost(m.EXPLOSION) + 10)
    for _ in range(4):
        g.press("triangle", vsyncs=3, settle=10)
        if s.wait(lambda: m.MAGIC_ITEM in s.menu_items(), 60, "", step=4, quiet=True) is not None:
            break
    s.wait_ready(m.MAGIC_ITEM)
    s.nav(range(0, 10), m.MAGIC_ITEM)
    g.press("circle", vsyncs=3, settle=10)
    s.wait_ready(m.WARLOCK_ITEM)
    s.nav(range(10, 15), m.WARLOCK_ITEM)
    g.press("circle", vsyncs=3, settle=10)
    s.wait_ready(m.SPELL_ITEM)
    g.run(10)
    s.nav(range(m.SPELL_ITEM, m.SPELL_ITEM + len(spells)), m.SPELL_ITEM + spells.index(m.EXPLOSION))
    g.press("circle", vsyncs=3, settle=4)
    s.wait(lambda: s.levels()[1] == 2, 60, "the LV picker")
    for button in ("right", "left", "right", "right", "left"):
        g.press(button, vsyncs=3, settle=20)
    g.run(40)


def scene_menuf(g, cp, symbols):
    """MENUF's screens, each played through and again skipped (classic_parity.py tour_menuf)."""
    cp.tour_menuf(g, symbols, lambda *args, **kwargs: None, lambda: None)


def tour(name):
    """classic_parity.py's tour `name` from a fresh game (each opens its screen itself): its pad work and waits, hashed."""
    def scene(g, cp, symbols):
        import collections
        getattr(cp, f"tour_{name}")(g, symbols, lambda *args, **kwargs: None, lambda: collections.defaultdict(int))
    return scene


CHECKPOINT = {"dialogue": "first_bubble", "title": "title", "opening": "title"}  # (the routes that do not start in the save room)


def scene_dialogue(g, cp, symbols):
    """The duke's talk bubble (the first_bubble checkpoint, no card): its zoom; every bubble shape the frames' table has,
    each flip and tail, written into the open box's fields (classic_parity.py tour_text_frame); the next lines."""
    import struct
    boxes, table = symbols["vs_battle_textBoxes"], symbols["D_800EB588"]
    ptr = cp.PTR
    g.run(200)

    def open_box():
        for i in range(8):
            flags = struct.unpack_from("<I", g.read(boxes + i * 0x30, 4))[0]
            state = struct.unpack("<h", g.read(boxes + i * 0x30 + 0x1C, 2))[0]
            if state != 0 and (flags & 15) in (2, 7):
                return i, flags
        return None, None
    box, flags = open_box()
    if box is None:
        raise SystemExit("build_compare dialogue: no talk bubble open")
    shapes = [k for k in range(16) if int.from_bytes(g.read(table + k * ptr, ptr), "little")]
    try:
        for shape in shapes:
            for flip in range(4):
                for tail in range(4):
                    g.write(boxes + box * 0x30, struct.pack("<I", (flags & ~0xFFC0) | flip << 6 | shape << 8 | tail << 12
                                                            | (flags & 0xFFFF0000)))
                    g.run(3)
    finally:
        g.write(boxes + box * 0x30, struct.pack("<I", flags))
    for _ in range(3):  # the next lines: the bubble closes, the next one opens and zooms in
        g.press("circle", vsyncs=3, settle=0)
        g.run(300)


def scene_title(g, cp, symbols):
    """The title (no card needed to rest): its menu idle, then Start and Continue: the LOAD screen (TITLE 22C.c's copy of
    the file menu): the cards, card 1's files walked past the last page and back, the first file loaded."""
    def press(button, settle=8):
        g.press(button, vsyncs=3, settle=settle)
    g.run(300)
    g.press("start", vsyncs=4, settle=90)
    for button in ("down", "up", "down", "up"):
        press(button, 30)
    press("circle", 90)  # Continue: the LOAD screen, its cards
    for button in ("down", "up", "down", "up"):
        press(button)
    press("circle", 90)  # card 1's files
    for button in ("down",) * 17 + ("up",) * 17:
        press(button, 4)
    press("cross", 60)
    press("circle", 90)
    g.run(30)
    press("circle", 0)  # its first file: loaded
    g.run(500)


def parity_tour(name, scale=1):
    """One of classic_parity.py's battle HUD tours (tour_<name>(g, check, counters)) from the save room, the gate's parity mode on
    (the game draws its own packets, which is what is compared; the claims only compare). `scale`: the UI text scale (the
    popups are drawn that much larger by ui_text: ui_text font is on in these games). Known: against a build older than 739f4c808
    actor_word_x2's frames 667-668 (two labels at once) differ: that build scaled a label 2x for two frames on a stale member
    address of the popup placement (ui_text.c); later builds keep it at normal size, as in the frames before."""
    def scene(g, cp, symbols):
        g.call("classic", parity=True, reset=True)
        g.call("ui_text", scale=scale)
        getattr(cp, f"tour_{name}")(g, lambda ok, message="": ok, lambda kind: g.call("classic")["kinds"][kind])
    return scene


def weather(zone, room):
    """A room with weather, left to run: zone 40 (Snowfly Forest) has the motes (146C.c func_80090434), zone 48 the rain
    (func_8008F440); no room has the snow or the falling particles (a scan of all 419 rooms), whose code is gone."""
    def scene(g, cp, symbols):
        g.call("room_goto", zone=zone, room=room, enemies=False, scripts=False)
        for _ in range(80):
            g.run(20)
            if g.call("room_goto", action="status")["phase"] in (0, 4):
                break
        g.run(400)
    return scene


def scene_opening(g, cp, symbols):
    """New Game's opening (the title, no card: Start, Circle): its picture cards (func_800CCA90's tiled drawer, the scaled and
    fading images), the manor's exterior in the rain and the first dialogue, left to play with Circle now and then."""
    g.run(60)
    g.press("start", vsyncs=4, settle=90)
    g.press("circle", vsyncs=3, settle=0)
    for step in range(60):
        g.run(60)
        if step % 4 == 3:
            g.press("circle", vsyncs=2, settle=4)


def popups(scale):
    """The damage and heal numbers (HP and MP, both signs, one to three digits) shown over the party, at UI text scale `scale`."""
    def scene(g, cp, symbols):
        g.call("classic", parity=True, reset=True)
        g.call("ui_text", scale=scale)
        for pool in ("hp", "mp"):
            for sign in (-1, 1):
                for value in (1, 9, 57, 100, 999):
                    g.call("hud", action="show", kind="damage", hold=True, pool=pool, sign=sign, value=value, age=10)
                    g.run(12)
        g.call("hud", action="clear")
        g.run(10)
    return scene


def scene_transition(g, cp, symbols):
    """The screen transition's drawing (146C.c _drawScreenTransition): each effect (fade to black, to white, the wipe at both
    wipe angles) held at a few alphas, written each step (the transition's own step stays idle, so the room goes on)."""
    effect, alpha, angle = (symbols[n] for n in ("vs_battle_screenTransitionEffect", "vs_battle_screenTransitionAlpha",
                                                   "vs_battle_screenTransitionWipeAngle"))
    size = cp.PTR if False else 4
    g.run(120)
    for kind in (0, 1, 2, 4, 5):
        for wipe_angle in ((0, 1024, 2048) if kind == 2 else (0,)):
            for level in (16, 64, 128, 200, 254, 255):
                g.write(effect, kind.to_bytes(4, "little"))
                g.write(angle, wipe_angle.to_bytes(4, "little"))
                g.write(alpha, level.to_bytes(4, "little"))
                g.run(2)
    g.write(alpha, (0).to_bytes(4, "little"))
    g.run(20)


def scene_gameover(g, cp, symbols):
    """The game over's LOAD (MENU7 vs_menu7_gameOver): Ashley's HP to 0, Continue, the cards, card 1's files walked, the
    first file loaded."""
    import struct
    PTR = cp.PTR

    def press(button, settle=8):
        g.press(button, vsyncs=3, settle=settle)

    def ashley():
        actor = int.from_bytes(g.read(symbols["vs_battle_actors"], PTR), "little")
        try:
            return actor and g.actor_stats(actor)
        except Exception:
            return 0
    g.until(ashley, step=10, guard=600, what="Ashley in the room")
    g.run(60)
    g.write(ashley() + 0x18, (0).to_bytes(2, "little"))
    g.until(lambda: g.state()["game_over"], step=10, guard=200, what="Game Over")
    g.run(240)
    for _ in range(6):
        press("circle", 30)
        g.run(30)
    g.run(90)
    for button in ("down", "up"):
        press(button)
    press("circle", 90)
    for button in ("down",) * 17 + ("up",) * 17:
        press(button, 4)
    g.run(30)
    press("circle", 0)
    g.run(400)


SCENES = {"levelled": scene_levelled, "ending": scene_ending, "menuf": scene_menuf, "mainmenu": scene_mainmenu, "manual": scene_manual,
          "score": tour("score"), "map": tour("map"), "status": tour("status"), "setup": tour("setup"), "items": tour("items"),
          "magic": tour("magic"), "arts": tour("arts"), "abilities": tour("abilities"), "data": tour("data"),
          "loot": tour("loot"), "storage": tour("storage"), "dialogue": scene_dialogue, "title": scene_title,
          "gameover": scene_gameover, "damage": popups(1), "damage_x2": popups(2), "actor_word_x2": parity_tour("actor_word", 2),
          "text_band_x2": parity_tour("text_band", 2), "buff_x2": parity_tour("buff", 2), "transition": scene_transition, "opening": scene_opening, "forest": weather(40, 0), "rain": weather(48, 1),
          **{n: parity_tour(n) for n in ("gauges", "figure", "status_icons", "battle_mode", "buff", "actor_word", "timer", "text_band",
                                        "target_row", "target_line", "ability_icons")}}
def play_menus(binary, card, out, names, sample, claims, aspect="4:3", extra_env=(), renderer="vulkan", settings_lines=()):
    """The routes of `names`, each in a game of its own: {route: [display hashes]}."""
    os.environ.update(ROOD_BINARY=binary, ROOD_SYMBOLS=binary, ROOD_HEADLESS="egl", ROOD_RENDERER=renderer, ROOD_ARCH="64",
                      ROOD_TEST_SNAPSHOTS="0")
    sys.path[:0] = [str(ROOT / "pc/tools"), str(ROOT / "pc/tests")]
    cover(binary)
    import classic_parity as cp
    import rood_rpc
    from checkpoints import launch_at
    out = pathlib.Path(out)
    (out / "plugins").mkdir()
    settings = out / "settings.cfg"
    lines = {"ui_menus": "0", "ui_text": "font", "interpolate": "0", "aspect": aspect}
    lines.update(kv.split(" ", 1) for kv in settings_lines)
    settings.write_text("".join(f"{k} {v}\n" for k, v in lines.items()))
    env = {"ROOD_SETTINGS": str(settings), "ROOD_PLUGINS": str(out / "plugins"), "ROOD_PLUGIN_DATA": str(out / "plugin_data"),
           "ROOD_GI": "0", "ROOD_AUDIO": "none", "ROOD_WINDOW": "1280x720" if aspect == "16:9" else "960x720", "ROOD_LIGHTS": str(out / "lights"),
           "ROOD_PREFABS": str(out / "prefabs"), "ROOD_OUT": str(out)}
    env.update(kv.split("=", 1) for kv in extra_env)
    if renderer == "null":  # (the CPU reference frame: no GPU, the original drawing; quicker and the manual opens)
        env["SDL_VIDEO_DRIVER"] = "invalid-null-classic-parity"
    if claims == "on":
        env["ROOD_PLUGINS_SHIPPED"] = str(ROOT / "pc/plugins")
    results = {}
    for name in names:
        card_copy = out / f"card-{name}.mcd"
        if name in ("dialogue", "opening"):  # (no card: the title's cursor then rests on New Game, the checkpoint's way in)
            card_copy = out / "no-card.mcd"
        else:
            card_copy.write_bytes(pathlib.Path(card).read_bytes())
        g = launch_at(CHECKPOINT.get(name, "save_room"), card=str(card_copy), fast=True, log=out / f"{name}.log", extra_env=env)
        hashes = []
        try:
            hashed(g, out, sample, hashes)
            SCENES[name](g, cp, rood_rpc.symbols())
            text = g.call("ui_text") if renderer != "null" else {}  # ui_text's word-level drawing: small-capital words and the status words drawn
        finally:
            g.close()
        results[name] = {"hashes": hashes, "word_glyphs": text.get("word_glyphs"), "item_words": text.get("item_words"),
                         "status_glyphs": (text.get("status") or {}).get("glyphs") if isinstance(text.get("status"), dict) else text.get("status_glyphs")}
    print("RESULT" + json.dumps(results))


def env_of(binary, args):
    """--new-env's settings, for NEW's runs only."""
    return args.new_env if binary == args.new else []


def run_menus(binary, args, names):
    with tempfile.TemporaryDirectory(prefix="build-compare-", dir=ROOT / "pc/build") as out:
        done = subprocess.run([sys.executable, __file__, "--play-menus", binary, "--menus", ",".join(names), "--menu-sample",
                               str(args.menu_sample), "--claims", args.claims, "--aspect", args.aspect, "--renderer", args.renderer] + [a for kv in args.setting for a in ("--setting", kv)] + [ "--card", args.card, "--out", out]
                              + [a for kv in env_of(binary, args) for a in ("--env", kv)],
                              capture_output=True, text=True)
    lines = [line for line in done.stdout.splitlines() if line.startswith("RESULT")]
    if not lines:
        sys.exit(f"build_compare: {binary} did not finish:\n{done.stderr[-1500:]}\n{done.stdout[-1500:]}")
    return json.loads(lines[-1][6:])


def compare_menus(args):
    names = [n for n in args.menus.split(",") if n]
    unknown = [n for n in names if n not in SCENES]
    if unknown:
        sys.exit(f"build_compare: no route {unknown} (have {', '.join(SCENES)})")
    first, control, new = run_menus(args.old, args, names), run_menus(args.old, args, names), run_menus(args.new, args, names)
    code = 0
    for name in names:
        a, b, c = first[name]["hashes"], control[name]["hashes"], new[name]["hashes"]
        words = [(r[name]["word_glyphs"], r[name]["status_glyphs"]) for r in (first, control, new)]
        noise, changed = differing({"frames": a}, {"frames": b}), differing({"frames": a}, {"frames": c})
        print(f"{name}: {len(a)} frames ({len(set(a))} distinct, every {args.menu_sample} vsyncs); control {len(noise)} differ; "
              f"old against new {len(changed)} differ{f' (first at frame {changed[0]})' if changed else ''}")
        print(f"{name}: ui_text word / status glyphs drawn: old {words[0]}, control {words[1]}, new {words[2]}"
              f", of the new's, found among draw items: {new[name]['item_words']}{'' if words[0] == words[2] else '  DIFFERENT'}")
        if noise:
            code = 2
        elif (changed or words[0] != words[2]) and code == 0:
            code = 1
    if code == 2:
        print("build_compare: the control differs, so this proves nothing")
    return code


def coverage(binary, sites):
    """(sites run, all sites, functions run, all functions) of the effect polygon calls in `binary`: the recorded return
    addresses against every call to pc_frame_poly_at, by the function holding each."""
    symbols = []
    for line in subprocess.run(["nm", "-n", "--defined-only", binary], capture_output=True, text=True).stdout.splitlines():
        parts = line.split()
        if len(parts) == 3 and parts[1] in "Tt":
            symbols.append((int(parts[0], 16), parts[2]))
    starts = [a for a, _ in symbols]

    def function(address):
        import bisect
        return symbols[bisect.bisect_right(starts, address) - 1][1]

    calls = []
    for line in subprocess.run(["objdump", "-d", "--no-show-raw-insn", binary], capture_output=True, text=True).stdout.splitlines():
        if "call" in line and "pc_frame_poly_at" in line:
            calls.append(int(line.split(":")[0], 16))
    ran = {function(a) for a in sites}
    every = {function(a) for a in calls}
    plugins = lambda names: {n.split("_")[0] for n in names if n.startswith("plg")}
    return len(set(sites)), len(calls), len(ran & every), len(every), len(plugins(ran)), len(plugins(every))


def run_casts(binary, args):
    keep = os.environ.get("ROOD_CAST_OUT")  # keep the game's logs here (a debug print in the game), one run per call
    with (contextlib.nullcontext(keep) if keep else tempfile.TemporaryDirectory(prefix="build-compare-", dir=ROOT / "pc/build")) as out:
        if keep:
            shutil.rmtree(keep, ignore_errors=True)
            os.makedirs(keep)
        done = subprocess.run([sys.executable, __file__, "--play-casts", binary, "--casts", args.casts, "--cast-limit",
                               str(args.cast_limit), "--card", args.card, "--out", out], capture_output=True, text=True)
    lines = [line for line in done.stdout.splitlines() if line.startswith("RESULT")]
    if not lines:
        sys.exit(f"build_compare: {binary} did not finish:\n{done.stderr[-1500:]}\n{done.stdout[-1500:]}")
    return json.loads(lines[-1][6:])


def compare_casts(args):
    first, control, new = run_casts(args.old, args), run_casts(args.old, args), run_casts(args.new, args)

    def differ(a, b):
        return [k for k in a["actions"] if a["actions"][k] != b["actions"].get(k)]
    noise, changed = differ(first, control), differ(first, new)
    done = [k for k, v in first["actions"].items() if v]
    print(f"{len(done)} actions cast ({len(first['actions']) - len(done)} refused here)")
    print(f"control (old against old): {len(noise)} actions differ")
    print(f"old against new: {len(changed)} actions differ{(': ' + ', '.join(changed[:8])) if changed else ''}")
    for name in changed[:3]:  # what differs first, by name (the samples' battle_state: the actors' and the effects' fields)
        a, b = first.get("states", {}).get(name), new.get("states", {}).get(name)
        if a and b and a[0] and b[0] and "effects" in a[0] and "effects" in b[0]:
            for step, (x, y) in enumerate(zip(a, b)):
                if x is None or y is None:
                    continue
                p, q = fields(x), fields(y)
                keys = [k for k in dict.fromkeys(list(p) + list(q)) if p.get(k) != q.get(k)]
                if keys:
                    print(f"  {name}: state differs from sample {step} ({len(keys)} fields): "
                          + "; ".join(f"{k}: {p.get(k)} -> {q.get(k)}" for k in keys[:4]))
                    if os.environ.get("ROOD_CAST_TRACE"):  # the effects of the samples around the first difference, both builds
                        for t in range(max(0, step - 3), min(len(a), len(b), step + 2)):
                            for label, run_ in (("old", a), ("new", b)):
                                for e in (run_[t] or {}).get("effects", [])[:2]:
                                    print(f"    {label} sample {t}: " + " ".join(f"{k}={e[k]}" for k in e if k not in ("particles", "end")
                                                                                 and not k.startswith("entry") or k in ("entry0", "entry1", "entry2")))
                    break
    if new["sites"]:
        ran, calls, fran, fall, pran, pall = coverage(args.new, new["sites"])
        print(f"effect polygon call sites run: {ran} of {calls}; functions {fran} of {fall}; plugins {pran} of {pall}; most items in a frame: {new['peak']}")
    else:
        print("effect polygon call sites: the new build does not record them (RPC effect_sites)")
    if noise:
        print("build_compare: the control differs, so this proves nothing")
        return 2
    return 0 if not changed else 1


def run(binary, args, width):
    with tempfile.TemporaryDirectory(prefix="build-compare-", dir=ROOT / "pc/build") as out:
        done = subprocess.run([sys.executable, __file__, "--play", binary, "--seconds", str(args.seconds), "--card", args.card,
                               "--out", out, "--width", str(width)], capture_output=True, text=True)
    lines = [line for line in done.stdout.splitlines() if line.startswith("RESULT")]
    if not lines:
        sys.exit(f"build_compare: {binary} did not finish:\n{done.stderr[-1500:]}")
    return json.loads(lines[-1][6:])


def differing(a, b):
    return [i for i, (x, y) in enumerate(zip(a["frames"], b["frames"])) if x != y] + list(range(min(len(a["frames"]), len(b["frames"])), max(len(a["frames"]), len(b["frames"]))))


def fields(state):
    """{slot.section.field: value} of one battle_state reply."""
    flat = {"rand": state["rand"]}
    for entry in state["actors"]:
        for section in ("actor", "object", "model", "ai"):
            for name, value in entry.get(section, {}).items():
                if name != "end":
                    flat[f"slot {entry['slot']} {section}.{name}"] = value
        if "slot" in entry:
            for section in ("actor", "object", "model", "ai"):
                flat.setdefault(f"slot {entry['slot']} {section}", entry.get(section) is not None)
    for index, effect in enumerate(state.get("effects", [])):
        for name, value in effect.items():
            if name == "particles":
                for k, text in enumerate(value[:-1]):
                    flat[f"effect {index} particle {k}"] = text
                flat[f"effect {index} particles"] = len(value) - 1
            elif name != "end":
                flat[f"effect {index} {name}"] = value
    flat["effects"] = len(state.get("effects", [])) - 1
    if "view" in state:
        flat["view"] = state["view"]
    return flat


def compare_states(old, new):
    """The first step whose actors', objects' or AI states differ, field by field: what the frames cannot show
    (an actor off screen). None when the builds agree or one lacks the RPC (printed)."""
    if not old["states"] or old["states"][0] is None or not new["states"] or new["states"][0] is None:
        print("states: not compared (a build without RPC battle_state)")
        return None
    for step, (a, b) in enumerate(zip(old["states"], new["states"])):
        x, y = fields(a), fields(b)
        keys = [k for k in dict.fromkeys(list(x) + list(y)) if x.get(k) != y.get(k)
                and not (k.startswith("effect") and ("effects" in a) != ("effects" in b))]  # (a build older than the effects dump)
        if keys:
            first = ", ".join(f"{k}: {x.get(k)} -> {y.get(k)}" for k in keys[:3])
            print(f"states: differ from step {step} ({step / 4:.2f} s), {len(keys)} fields: {first}")
            return step
    print(f"states: {len(old['states'])} steps, every named field of every actor equal")
    return None


def play_audio(binary, card, out):
    """The sound: the fight's room, then room 0 of zone 15 with its script (its entry sound effects), the mix recorded
    to out/audio.wav. Everything the sound drivers do reaches the wav, which no frame or actor field shows."""
    os.environ.update(ROOD_BINARY=binary, ROOD_SYMBOLS=binary, ROOD_HEADLESS="egl", ROOD_RENDERER="vulkan", ROOD_ARCH="64", ROOD_TEST_SNAPSHOTS="0")
    sys.path[:0] = [str(ROOT / "pc/tools"), str(ROOT / "pc/tests")]
    cover(binary)
    from checkpoints import launch_at
    out = pathlib.Path(out)
    g = launch_at("save_room", card=card, fast=True, log=out / "audio.log", audio=f"wav:{out / 'audio.wav'}", extra_env={
        "ROOD_GI": "0", "ROOD_INTERPOLATE": "0", "ROOD_WINDOW": "960x720", "ROOD_LIGHTS": str(out / "lights"), "ROOD_PREFABS": str(out / "prefabs")})
    try:
        g.call("room_goto", zone=ROOM[0], room=ROOM[1], enemies=True, scripts=False)
        for _ in range(80):
            g.run(20)
            if g.call("room_goto", action="status")["phase"] in (0, 4):
                break
        g.run(1200)
        g.call("room_goto", zone=15, room=0, enemies=True, scripts=True)
        g.run(900)
    finally:
        g.close()
    print("RESULT")


def run_audio(binary, args):
    """The recording's samples (the 44-byte header's length is only updated once a second: it is skipped)."""
    with tempfile.TemporaryDirectory(prefix="build-compare-", dir=ROOT / "pc/build") as out:
        done = subprocess.run([sys.executable, __file__, "--play-audio", binary, "--card", args.card, "--out", out], capture_output=True, text=True)
        wav = pathlib.Path(out) / "audio.wav"
        if "RESULT" not in done.stdout or not wav.exists():
            sys.exit(f"build_compare: {binary} did not finish the sound run:\n{done.stderr[-1500:]}")
        return wav.read_bytes()[44:]


def first_difference(a, b):
    """The first differing byte of two recordings (None when equal), found in blocks."""
    n, step = min(len(a), len(b)), 1 << 16
    for i in range(0, n, step):
        if a[i:min(i + step, n)] != b[i:min(i + step, n)]:
            j = next(k for k in range(i, min(i + step, n)) if a[k] != b[k])
            return j
    return None if len(a) == len(b) else n


def compare_audio(args):
    """Old, old again (the control) and new: 0 when the new recording is the old one, byte for byte."""
    first, control, new = run_audio(args.old, args), run_audio(args.old, args), run_audio(args.new, args)
    noise, changed = first_difference(first, control), first_difference(first, new)
    seconds = lambda i: i // 4 / 44100
    print(f"audio: control {'identical' if noise is None else f'differs from {seconds(noise):.2f} s'}; "
          f"old {len(first)} bytes, new {len(new)}; " + ("identical" if changed is None else f"first differs at {seconds(changed):.2f} s"))
    if noise is not None:
        print("build_compare: the control's audio differs, so the audio proves nothing")
        return 2
    return 0 if changed is None else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("old")
    parser.add_argument("new", nargs="?", default=str(ROOT / "pc/build/boot64/rood_battle_probe"))
    parser.add_argument("--card", default=str(ROOT / "pc/build/test-card1.mcd"))
    parser.add_argument("--seconds", type=int, default=30)
    parser.add_argument("--casts", nargs="?", const="spells", help="the wider lane: cast every spell (spells[,arts])")
    parser.add_argument("--cast-limit", type=int, default=0, help="--casts: stop after this many actions")
    parser.add_argument("--old-width", type=int, default=4, help="bytes of a pointer in OLD's drop nodes")
    parser.add_argument("--new-width", type=int, default=8, help="the same in NEW")
    parser.add_argument("--width", type=int, default=8, help=argparse.SUPPRESS)
    parser.add_argument("--play", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--play-casts", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--play-audio", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--audio", choices=["on", "off"], default="on", help="the sound lane after the fight: the room's recorded mix, old, old again and new, byte for byte")
    parser.add_argument("--menus", nargs="?", const="ending,menuf", help="the menus' lane: the routes to play (see the top of this file)")
    parser.add_argument("--menu-sample", type=int, default=MENU_SAMPLE, help="--menus: vsyncs between display hashes")
    parser.add_argument("--claims", choices=["on", "off"], default="on", help="--menus: rood.classic's claims on or off")
    parser.add_argument("--new-env", action="append", default=[], metavar="KEY=VALUE", help="--menus: set in NEW's game (a dev flag such as ROOD_CLASSIC_ITEMS=1)")
    parser.add_argument("--env", action="append", default=[], help=argparse.SUPPRESS)
    parser.add_argument("--renderer", choices=["vulkan", "null"], default="vulkan", help="--menus: null hashes the CPU reference frame (the original drawing, no GPU; no ui_text)")
    parser.add_argument("--setting", action="append", default=[], metavar="'KEY VALUE'", help="--menus: a settings.cfg line (ui_text original)")
    parser.add_argument("--aspect", choices=["4:3", "16:9"], default="4:3", help="--menus: the display's aspect")
    parser.add_argument("--play-menus", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--out", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.play:
        return play(args.old, args.seconds, args.card, args.out, args.width)
    if args.play_audio:
        return play_audio(args.old, args.card, args.out)
    if args.play_casts:
        return play_casts(args.old, args.card, args.out, args.casts, args.cast_limit)
    if args.play_menus:
        return play_menus(args.old, args.card, args.out, args.menus.split(","), args.menu_sample, args.claims, args.aspect, args.env, args.renderer, args.setting)
    if args.menus:
        return compare_menus(args)
    if args.casts:
        return compare_casts(args)
    first, control, new = run(args.old, args, args.old_width), run(args.old, args, args.old_width), run(args.new, args, args.new_width)
    noise, changed = differing(first, control), differing(first, new)
    print(f"control (old against old): {len(noise)} of {len(first['frames'])} frames differ")
    print(f"old against new: {len(changed)} of {len(first['frames'])} frames differ{f' (first at {changed[0] / 4:.2f} s)' if changed else ''}")
    print(f"casts: old {len(first['casts'])}, new {len(new['casts'])}; the same: {first['casts'] == new['casts']}")
    print(f"drops: old {len(first['drops'])}, new {len(new['drops'])}; the same: {first['drops'] == new['drops']}")
    state_noise = compare_states(first, control)
    state_changed = compare_states(first, new)
    if state_noise is not None:
        print("build_compare: the control's states differ, so the states prove nothing")
        return 2
    if noise:
        print("build_compare: the control differs, so this proves nothing")
        return 2
    if not first["casts"]:
        print("build_compare: no enemy cast in this run: extend --seconds")
        return 2
    if not first["drops"]:
        print("build_compare: no enemy dropped anything")
        return 2
    verdict = 0 if not changed and first["casts"] == new["casts"] and first["drops"] == new["drops"] and state_changed is None else 1
    if args.audio == "on":
        sound = compare_audio(args)
        verdict = verdict or sound
    return verdict


if __name__ == "__main__":
    sys.exit(main())
