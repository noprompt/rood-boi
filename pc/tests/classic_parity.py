#!/usr/bin/env python3
"""The classic look's parity gate (plan pc/docs/plans/2026-10-20-classic-ui-in-lua.md
§3; pc/src/classic/classic_parity.h): rood.classic's Lua draw of each kind it
owns against the game's own drawing of the same element in the same frame,
packet for packet.

    python3 pc/tests/classic_parity.py [--card pc/build/test-card1.mcd] [--out DIR]
        [--renderer null|gl|vulkan] [--kind status,chain]

One game from the save_room checkpoint (a copy of the card), the classic look
(ui_menus 0), the null renderer by default (packets need no GPU), the shipped
plugins only (rood.classic on), dev mode (the RPC):
  - parity (RPC classic {parity}): the game draws; at each hook rood.classic's
    claim draws into a shadow slot and both are normalised and compared. Each
    kind's states are held in turn with rood.dev.show's spawners (the game's
    own records): status, every timing word and success word at the ages of
    its slide in, held and slide out; chain, counts 1 (it slides in), 2, 3, 9,
    10 and 99 at the same ages. Each state is held until the gate has compared
    two of its frames (a condition, not a count of vsyncs);
  - waivers (pc/tests/classic/waivers.toml) equal the overrides rood.classic
    declares (its M.look.overrides), and no mismatch outside their fields;
  - the default and the fallback, the parity mode off: rood.classic draws each
    kind (claimed, suppressed, drawn); the kind's hud_classic_<kind> off, a
    draw that raises, the plugin off: the game draws it again, each time;
  - state parity (§3.4): from one mark, a held word with rood.classic drawing,
    then with the game drawing, leaves the game's memory the same every vsync
    (Oracle page digests; the primitive buffers, ordering tables and the
    packet pointer masked).
What packets cannot show (a host-side hide, widescreen's widening) is the other suites' to see: the classic
gate also runs cutscene_player_smoke and widescreen_smoke (run.py classic_parity hud classic
cutscene_player_smoke widescreen_smoke).
Reports: <out>/<kind>.json (frames compared, mismatches by
field, the first difference with both packets, waived fields, the states
covered). Exit 0 when every kind is green."""
import argparse
import json
import os
import pathlib
import shutil
import sys
import tomllib

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
sys.path.insert(0, str(ROOT / "pc/tests"))
import rood_rpc  # noqa: E402
from rood_rpc import OUT, RpcError  # noqa: E402
from checkpoints import launch_at  # noqa: E402
from card_fixtures import card_guard, default_save  # noqa: E402
from snapshot_diff import Symbols  # noqa: E402

TIMINGS = ["too_fast", "fast", "slow", "too_slow"]
SUCCESS = ["COOL!", "GOOD!", "EXCELLENT!", "RIGHT ON!", "PERFECT!", "WELL TIMED!", "NICE!", "GREAT!"]
WORDS = {"too_fast": "TOO FAST!", "fast": "FAST!", "slow": "SLOW!", "too_slow": "TOO SLOW!"}
CHAIN_COUNTS = [1, 2, 3, 9, 10, 99]
SLOTS = ["WEAPON", "SHIELD", "R.ARM", "L.ARM", "HEAD", "BODY", "LEGS"]
STATS = ["HUMAN", "BEAST", "UNDEAD", "PHANTOM", "DRAGON", "EVIL", "PHYSICS", "AIR", "FIRE", "EARTH", "WATER", "LIGHT",
         "DARKNESS"]
VALUES = [1, 9, 10, 99, 100, 999]  # one to three figures (the spawners cap at 999)
# The ages each kind's whole life must have shown: its slide in and out (func_800958A4: 64, 16, 4, 1 pixels
# at ages 0..3 and 45..42; func_80095A4C: the first chain's 0..3, every count's 90..87); a number's bounce
# (func_80094B0C: frames 0..15, then held at 15) and a stat's drift (half its age, to 30).
SLIDES = {"status": {0, 1, 2, 3, 42, 43, 44, 45}, "chain": {0, 1, 2, 3, 87, 88, 89, 90},
          "damage": set(range(17)) | {30}}
# The gauges' states (Ashley's HUD record written: hp, max_hp, mp, max_mp, risk): digits of one to four
# figures, empty and full bars, RISK ZERO and RISK's bar; then the display's slide out and back.
GAUGES = [(157, 253, 50, 50, 0), (1, 253, 0, 50, 0), (253, 253, 50, 50, 1), (9, 9, 7, 7, 55), (999, 999, 999, 999, 100),
          (1000, 1500, 120, 300, 99), (0, 253, 50, 50, 0)]
PTR = 8 if os.environ.get("ROOD_ARCH") == "64" else 4  # host pointers (vs_battle_actors)


def states(kind):
    """(the show's args, the element's text) for every element of kind the gate plays."""
    if kind == "status":
        for timing in TIMINGS:
            yield {"timing": timing}, WORDS[timing]
        for variant, word in enumerate(SUCCESS):
            yield {"timing": "success", "variant": variant}, word
    elif kind == "chain":
        for count in CHAIN_COUNTS:
            yield {"count": count}, f"{count} CHAIN" + ("" if count == 1 else "S")
    elif kind == "buff":
        # every equipment word and every class / affinity word, both signs, digits of one to three figures
        for i, slot in enumerate(SLOTS):
            yield {"slot": slot, "stat": STATS[i], "value": 1 + i, "sign": 1}, f"{slot} {STATS[i]} +{1 + i}"
        for i, stat in enumerate(STATS):
            yield {"slot": SLOTS[i % 7], "stat": stat, "value": 2, "sign": -1}, f"{SLOTS[i % 7]} {stat} -2"
        for value in VALUES:
            for sign in (1, -1):
                yield ({"slot": "WEAPON", "stat": "HUMAN", "value": value, "sign": sign},
                       f"WEAPON HUMAN {'+' if sign > 0 else '-'}{value}")
    elif kind == "damage":
        # HP and MP, damage and healing (four colours, both bounces), one to three figures; each stat's
        # icon, its sign and drift both ways
        for pool in ("hp", "mp"):
            for sign in (-1, 1):
                for value in VALUES:
                    yield {"pool": pool, "sign": sign, "value": value}, str(value)
        for stat in range(6):
            for sign in (-1, 1):
                yield {"pool": "stat", "stat": stat, "sign": sign, "value": 12 + stat}, str(12 + stat)


def stats_address(g):
    """Ashley's HUD record's currentHP (vs_battle_actors[0] -> +0x3c -> +0x18: HP, max, MP, max, risk)."""
    symbols = rood_rpc.symbols()
    actor = int.from_bytes(g.read(symbols["vs_battle_actors"], PTR), "little")
    record = int.from_bytes(g.read(actor + 0x3C, 4), "little")
    return record + 0x18


def tour_gauges(g, check, counters):
    """The gauges through their states and the display's slide; the ages are the states compared."""
    import struct
    at = stats_address(g)
    original = g.read(at, 10)
    covered = []
    try:
        for hp, max_hp, mp, max_mp, risk in GAUGES:
            g.write(at, struct.pack("<hhhhH", hp, max_hp, mp, max_mp, risk))
            before = counters("gauges")["frames"]
            ok = g.until(lambda: counters("gauges")["frames"] >= before + 2, guard=60)
            c = counters("gauges")
            if check(bool(ok), f"gauges HP {hp}/{max_hp} MP {mp}/{max_mp} risk {risk}: compared ({c['frames']} frames, "
                               f"{c['mismatched']} mismatched, '{c['text']}')"):
                covered.append({"hp": hp, "max_hp": max_hp, "mp": mp, "max_mp": max_mp, "risk": risk})
        # the slide: out (D_800EB9AF, as a menu opening sets it) until hidden, then back
        symbols = rood_rpc.symbols()
        before = counters("gauges")["frames"]
        g.write(symbols["D_800EB9AF"], b"\x01")
        out = g.until(lambda: int.from_bytes(g.read(symbols["D_800EB9B0"], 4), "little") == 0x200000, step=1, guard=60)
        g.write(symbols["D_800EB9AF"], b"\x00")
        back = g.until(lambda: int.from_bytes(g.read(symbols["D_800EB9B0"], 4), "little") == 0, step=1, guard=60)
        frames = counters("gauges")["frames"] - before
        if check(bool(out) and bool(back) and frames >= 6, f"gauges: the display slid out and back ({frames} frames "
                                                            f"compared)"):
            covered.append({"slide": "out and back"})
    finally:
        g.write(at, original)
    return covered


def tour_figure(g, check, counters):
    """Both stances, every limb condition, mixed conditions, and the game's visibility gates."""
    import struct
    symbols = rood_rpc.symbols()
    at = stats_address(g) - 0x18 + 0x398
    limbs = [at + i * 0xDC for i in range(5)]
    saved = [g.read(a, 4) for a in limbs]
    stance_at = symbols["D_800EB9CC"]
    stance = g.read(stance_at, 1)
    covered = []
    try:
        for pose in (0, 1):
            for hp in (0, 1, 2, 24, 25, 74, 75, 99, 100):
                g.write(stance_at, bytes([pose]))
                for a in limbs:
                    g.write(a, struct.pack("<hh", hp, 100))
                before = counters("figure")["frames"]
                ok = g.until(lambda: counters("figure")["frames"] >= before + 2, guard=60)
                check(bool(ok), f"figure stance {pose}, all limbs {hp}/100: compared")
                e = next(e for e in g.call("hud", action="list")["elements"] if e["kind"] == "figure" and e["live"])
                condition = 0 if hp < 2 else 1 if hp < 25 else 2 if hp < 75 else 3 if hp < 100 else 4
                check(e["stance"] == pose and all(e[f"limb_{i}_status"] == condition for i in range(5)),
                      f"figure stance {pose}, {hp}/100: read-only condition fields {condition}")
                covered.append({"stance": pose, "hp": [hp] * 5})
            for i, a in enumerate(limbs):
                g.write(a, struct.pack("<hh", [1, 24, 50, 99, 100][i], 100))
            before = counters("figure")["frames"]
            check(bool(g.until(lambda: counters("figure")["frames"] >= before + 2, guard=60)),
                  f"figure stance {pose}, mixed conditions: compared")
            e = next(e for e in g.call("hud", action="list")["elements"] if e["kind"] == "figure" and e["live"])
            check(e["stance"] == pose and [e[f"limb_{i}_status"] for i in range(5)] == list(range(5)),
                  f"figure stance {pose}: mixed read-only conditions")
            covered.append({"stance": pose, "hp": [1, 24, 50, 99, 100]})
        # Menu slide and lower-screen visibility: no hook while hidden; restored drawing afterwards.
        for name, hidden in (("D_800EB9AF", 1), ("vs_battle_lowerScreenUiState", 2)):
            address = symbols[name]
            original = g.read(address, 1)
            try:
                g.write(address, bytes([hidden]))
                before = counters("figure")["frames"]
                g.run(12)
                check(counters("figure")["frames"] == before, f"figure hidden by {name}: no packets")
                covered.append({"hidden": name})
            finally:
                g.write(address, original)
            before = counters("figure")["frames"]
            check(bool(g.until(lambda: counters("figure")["frames"] >= before + 2, guard=60)),
                  f"figure restored after {name}")
    finally:
        for a, value in zip(limbs, saved):
            g.write(a, value)
        g.write(stance_at, stance)
    return covered


def status_icons_fixture(g, statuses=0x1FFE0, phase=0, current=0, previous=255, next_icon=1):
    """Guest status bits, not a new spawner: the game still decides carousel transitions."""
    import struct
    symbols = rood_rpc.symbols()
    at = stats_address(g) - 0x18 + 0x948
    g.write(at, struct.pack("<I", statuses) + b"\xff" * 8)
    g.write(symbols["D_800EB9D0"], bytes([previous, current, next_icon, phase]))


def tour_status_icons(g, check, counters):
    """Every icon on/off and clipped, both CLUTs, stat glyphs, counts, carousel phases and speeds."""
    import struct
    symbols = rood_rpc.symbols()
    at = stats_address(g) - 0x18 + 0x948
    saved = [(at, g.read(at, 12))]
    for name, size in (("D_800EB9D0", 4), ("D_800EB9AE", 1), ("D_800EB9AF", 1),
                       ("D_800EB9B0", 4), ("vs_gametime_tickspeed", 4)):
        saved.append((symbols[name], g.read(symbols[name], size)))
    mapped = struct.unpack("<8H", g.read(symbols["D_800EBC68"], 16))
    covered = []

    def compared(label, **fields):
        before = counters("status_icons")["frames"]
        ok = g.until(lambda: counters("status_icons")["frames"] >= before + 2, step=1, guard=60)
        check(bool(ok), "status_icons " + label + ": compared")
        covered.append({"scenario": label, **fields})

    try:
        for icon in range(32):
            raw = 1 << (icon + 5) if icon < 16 else next(1 << (i + 21) for i, m in enumerate(mapped) if m & (1 << (icon - 16)))
            status_icons_fixture(g, raw, current=icon, previous=icon, next_icon=icon)
            compared(f"icon {icon} on", icon=icon, statuses=raw)
            e = next(e for e in g.call("hud", action="list")["elements"] if e["kind"] == "status_icons" and e["live"])
            check(e["current"] == icon, f"status_icons read-only current is icon {icon}")
            # Each icon exercises its own crop and (for 16..31) supplemental glyph, including zero width.
            for phase in (9, 11, 12, 15):
                status_icons_fixture(g, raw, phase=phase, current=icon, previous=icon, next_icon=icon)
                compared(f"icon {icon} clipped phase {phase}", icon=icon, phase=phase)
            status_icons_fixture(g, 0)
            before = counters("status_icons")["frames"]
            g.run(8)
            check(counters("status_icons")["frames"] == before, f"status_icons icon {icon} off: no packets")
            covered.append({"scenario": "off", "icon": icon})
        for count in (1, 2, 3, 8, 9, 16, 32):
            raw = ((1 << count) - 1) << 5 if count <= 16 else 0x1FFFFFE0
            status_icons_fixture(g, raw)
            compared(f"count {count}", count=count)
            e = next(e for e in g.call("hud", action="list")["elements"] if e["kind"] == "status_icons" and e["live"])
            check(e["count"] == count, f"status_icons read-only count is {count}")
            g.run(64)  # unpinned full carousel lives, not just held phases
        for speed in (2, 4):
            g.write(symbols["vs_gametime_tickspeed"], struct.pack("<I", speed))
            for phase in range(16):
                status_icons_fixture(g, phase=phase, current=7, previous=6, next_icon=8)
                compared(f"speed {speed} phase {phase}", speed=speed, phase=phase)
            check(int.from_bytes(g.read(symbols["vs_gametime_tickspeed"], 4), "little") == speed,
                  f"status_icons tickspeed {speed} held by game")
        # Invalidate all three slots, rotate on phase 12, and select the second indicator row.
        for previous, current, next_icon in ((31, 30, 29), (0, 8, 1), (8, 0, 8)):
            status_icons_fixture(g, phase=12, previous=previous, current=current, next_icon=next_icon)
            compared(f"slot removal/rotation {previous}/{current}/{next_icon}")
        status_icons_fixture(g)
        for hidden in (1, 0):
            g.write(symbols["D_800EB9AE"], bytes([hidden]))
            if hidden:
                before = counters("status_icons")["frames"]
                g.run(8)
                check(counters("status_icons")["frames"] == before, "status_icons disabled: no packets")
                covered.append({"scenario": "disabled"})
            else:
                compared("enabled again")
        g.write(symbols["D_800EB9AF"], b"\x01")
        check(bool(g.until(lambda: int.from_bytes(g.read(symbols["D_800EB9B0"], 4), "little") == 0x200000,
                           step=1, guard=60)), "status_icons slide out")
        g.write(symbols["D_800EB9AF"], b"\x00")
        check(bool(g.until(lambda: int.from_bytes(g.read(symbols["D_800EB9B0"], 4), "little") == 0,
                           step=1, guard=60)), "status_icons slide back")
        compared("slide out and back")
    finally:
        for a, value in saved:
            g.write(a, value)
    return covered


def battle_mode_fixture(g, mode=1, step=4, phase=0):
    symbols = rood_rpc.symbols()
    g.write(symbols["D_800EB9CC"], bytes([mode]))
    g.write(symbols["D_800EB9CD"], bytes([step]))
    g.write(symbols["D_800EBD64"], phase.to_bytes(4, "little"))


def tour_battle_mode(g, check, counters):
    """Entry, exit, packed-colour pulse extrema/wrap, and the pre-update panel displacement."""
    symbols = rood_rpc.symbols()
    saved = [(symbols[n], g.read(symbols[n], size)) for n, size in
             (("D_800EB9CC", 1), ("D_800EB9CD", 1), ("D_800EBD64", 4),
              ("D_800EB9AF", 1), ("D_800EB9B0", 4), ("vs_gametime_tickspeed", 4))]
    covered = []

    def frame(label, expected_step=None, expected_slide=None, expected_pulse=None):
        before = counters("battle_mode")["frames"]
        check(bool(g.until(lambda: counters("battle_mode")["frames"] > before, step=1, guard=60)),
              "battle_mode " + label + ": compared")
        e = next(e for e in g.call("hud", action="list")["elements"] if e["kind"] == "battle_mode" and e["live"])
        check(e["anchor"] == 2, "battle_mode right anchor")
        for key, value in (("step", expected_step), ("slide", expected_slide), ("pulse", expected_pulse)):
            if value is not None:
                check(e[key] == value, f"battle_mode {label}: {key} {e[key]} = {value}")
        covered.append({"scenario": label, "step": e["step"], "slide": e["slide"], "pulse": e["pulse"]})

    try:
        g.write(symbols["D_800EB9AF"], b"\x00")
        g.write(symbols["D_800EB9B0"], bytes(4))
        for step in range(4):
            battle_mode_fixture(g, step=step, phase=1024)
            frame(f"entry {step + 1}", expected_step=step + 1, expected_pulse=0)
        for step in (4, 3, 2):
            battle_mode_fixture(g, mode=0, step=step)
            frame(f"exit {step - 1}", expected_step=step - 1)
        battle_mode_fixture(g, mode=0, step=1)
        before = counters("battle_mode")["frames"]
        g.run(12)
        check(counters("battle_mode")["frames"] == before, "battle_mode fully hidden: no packets")
        covered.append({"scenario": "hidden"})
        for speed in (2, 4):
            g.write(symbols["vs_gametime_tickspeed"], speed.to_bytes(4, "little"))
            for phase in (0, 1, 512, 1023, 1024, 1025, 1536, 2047, 2048, 3072, 4095):
                battle_mode_fixture(g, phase=phase)
                frame(f"speed {speed} phase {phase}", expected_step=4,
                      expected_pulse=0 if phase in (0, 2048) else 128 if phase in (1024, 3072) else None)
            g.run(64)  # an entire unpinned pulse period at each tickspeed
        for hidden in (1, 0):
            g.write(symbols["D_800EB9AF"], bytes([hidden]))
            for slide in ((0, 8, 16, 24, 32) if hidden else (32, 24, 16, 8, 0)):
                g.write(symbols["D_800EB9B0"], (slide << 16).to_bytes(4, "little"))
                battle_mode_fixture(g, phase=1024)
                frame(f"panel {'out' if hidden else 'back'} {slide}", expected_slide=slide << 16)
        battle_mode_fixture(g, step=0)
        g.run(40)
        covered.append({"scenario": "uninterrupted entry and pulse"})
        battle_mode_fixture(g, mode=0)
        g.run(20)
        covered.append({"scenario": "uninterrupted exit"})
    finally:
        for at, value in saved:
            g.write(at, value)
    return covered


def label_pool(g):
    """The label records (D_800F1BAC: 24-byte D_800F1BAC_t) and their count (D_800F227E)."""
    symbols = rood_rpc.symbols()
    pool = int.from_bytes(g.read(symbols["D_800F1BAC"], PTR), "little")
    return pool, g.read(symbols["D_800F227E"], 1)[0]


def tour_buff(g, check, counters):
    """A buff pushed up by the buffs shown after it: the record's rise (unk12, 10 for each) written, as the
    label loop writes it when a later one appears; the spawner shows each at once (none waits behind)."""
    covered = []
    g.call("hud", action="show", kind="buff", hold=True, age=10, slot="BODY", stat="FIRE", value=3, sign=1)
    for rise in (10, 20, 30):
        pool, count = label_pool(g)
        at = next((pool + i * 24 for i in range(count) if g.read(pool + i * 24 + 8, 1)[0] in (6, 7)), None)
        if not check(at is not None, f"buff rise {rise}: its record"):
            break
        g.write(at + 0x12, rise.to_bytes(2, "little"))
        before = counters("buff")["frames"]
        ok = g.until(lambda: counters("buff")["frames"] >= before + 2, guard=60)
        e = next((e for e in g.call("hud", action="list")["elements"] if e["kind"] == "buff" and e["live"]), None)
        check(bool(ok) and e is not None and e["rise"] == rise, f"buff BODY FIRE +3 risen {rise}: compared, read-only "
                                                                f"rise {e and e['rise']}")
        covered.append({"slot": "BODY", "stat": "FIRE", "value": 3, "rise": rise})
    g.call("hud", action="clear")
    return covered


LABELS = 29  # the combat labels with pieces (D_800690B4: 29..31 have none)


def spawn_word(g, kind=2, flags=0, index=0, age=0):
    """A word over Ashley as the game's spawners make one (func_8009406C: kind 2, a combat label, flags bit 0 a
    lowered stat's; func_80093B68 with type 2: kind 1, MISS), appended to the label pool; returns its address.
    (D_800F227A 0: Ashley's words shown, as when no action has hidden them.)"""
    import struct
    symbols = rood_rpc.symbols()
    pool, count = label_pool(g)
    if count >= 30:
        return None
    g.write(symbols["D_800F227A"], bytes(2))
    spread = 0x1000 if kind == 1 else 0  # (kind 1: the number's spread not yet placed)
    at = pool + count * 24
    g.write(at, struct.pack("<hhhhBBBBHBBhh4s", 0, 0, 0, 0, kind, 0, 0xFB if kind == 2 else 255, age, index, flags,
                            0, spread, spread, bytes(4)))
    g.write(symbols["D_800F227E"], (count + 1).to_bytes(2, "little"))
    return at


def keep_word(g):
    """The default and fallback checks' word: a combat label kept at age 10 (written each poll), respawned when
    gone."""
    pool, count = label_pool(g)
    for i in range(count):
        if g.read(pool + i * 24 + 8, 1)[0] == 2 and g.read(pool + i * 24 + 12, 2) == b"\x05\x00":
            g.write(pool + i * 24 + 11, bytes([10]))
            return
    spawn_word(g, index=5, age=10)


def tour_actor_word(g, check, counters):
    """Every combat label's whole life, plain and as a lowered stat's (its arrow), MISS from both of the label
    loop's MISS calls (kinds 1 and 2), and two words at once; every age compared."""
    covered, ages = [], set()

    def life(label, **spawn):
        before = counters("actor_word")["frames"]
        at = spawn_word(g, **spawn)
        if not check(at is not None, f"actor_word {label}: spawned"):
            return
        seen = set()

        def gone():
            live = [e for e in g.call("hud", action="list")["elements"] if e["kind"] == "actor_word" and e["live"]]
            seen.update(e["age"] for e in live)
            return not live and seen
        ok = g.until(gone, step=1, guard=60)
        frames = counters("actor_word")["frames"] - before
        check(bool(ok) and frames >= len(seen), f"actor_word {label}, its life: {frames} frames compared, ages "
                                                f"{min(seen) if seen else '-'}..{max(seen) if seen else '-'}")
        ages.update(seen)
        covered.append({"word": label, **spawn, "ages": sorted(seen)})

    for index in range(LABELS):
        life(f"label {index}", index=index)
        life(f"label {index} lowered", index=index, flags=1)
    life("MISS (a number's)", kind=1, flags=2)
    life("MISS (a word's)", kind=2, flags=2)
    before = counters("actor_word")["frames"]
    spawn_word(g, index=1)
    spawn_word(g, index=21, flags=1)
    g.run(20)
    elements = [e for e in g.call("hud", action="list")["elements"] if e["kind"] == "actor_word" and e["live"]]
    check(len(elements) == 2 and counters("actor_word")["frames"] >= before + 2,
          f"actor_word: two words at once ({len(elements)} live) compared")
    covered.append({"word": "two at once"})
    g.run(40)
    check(set(range(31)) <= ages, f"actor_word: every age 0..30 covered (missing {sorted(set(range(31)) - ages)})")
    return covered


TIMERS = [(0, 0, 0, 0), (0, 0, 1, 0), (1, 2, 3, 0), (4, 5, 6, 0), (7, 8, 9, 0), (9, 9, 9, 0), (10, 10, 10, 0),
          (23, 45, 67, 0), (47, 47, 47, 0), (38, 16, 82, 0), (0, 59, 99, 0), (59, 59, 98, 0), (12, 34, 56, 1)]  # minutes, seconds, hundredths, the overflow byte (59:59:99 whatever the rest)


def timer_fixture(g, minutes=0, seconds=0, hundredths=0, over=0, shown=1):
    """The time attack's timer as its state holds it: D_8005046C's seconds, minutes and overflow bytes,
    vs_main_stateFlags.puzzleTimerHundredths (+0xA0), vs_battle_lowerScreenUiState 1 (the lower screen shows
    it)."""
    symbols = rood_rpc.symbols()
    g.write(symbols["D_8005046C"] + 1, bytes([seconds, minutes, over]))
    g.write(symbols["vs_main_stateFlags"] + 0xA0, bytes([hundredths]))
    g.write(symbols["vs_battle_lowerScreenUiState"], bytes([shown]))


def tour_timer(g, check, counters):
    """Digits of every place 0..9 and their carries' boundaries, the overflow (59:59:99), then the timer
    hidden and shown again."""
    symbols = rood_rpc.symbols()
    saved = [(symbols[n] + o, g.read(symbols[n] + o, size)) for n, o, size in
             (("D_8005046C", 0, 4), ("vs_main_stateFlags", 0xA0, 1), ("vs_battle_lowerScreenUiState", 0, 1))]
    covered = []
    try:
        for minutes, seconds, hundredths, over in TIMERS:
            timer_fixture(g, minutes, seconds, hundredths, over)
            text = "59:59:99" if over else f"{minutes:02}:{seconds:02}:{hundredths:02}"
            before = counters("timer")["frames"]
            ok = g.until(lambda: counters("timer")["frames"] >= before + 2, step=1, guard=60)
            e = next((e for e in g.call("hud", action="list")["elements"] if e["kind"] == "timer" and e["live"]), None)
            check(bool(ok) and e is not None and e["text"] == text
                  and (e["minutes"], e["seconds"], e["hundredths"]) == tuple(int(text[i:i + 2]) for i in (0, 3, 6)),
                  f"timer {text}: compared, read-only fields {e and (e['minutes'], e['seconds'], e['hundredths'])}")
            covered.append({"text": text})
        timer_fixture(g, shown=0)
        before = counters("timer")["frames"]
        g.run(12)
        check(counters("timer")["frames"] == before, "timer hidden: no packets")
        covered.append({"hidden": True})
        timer_fixture(g, 3, 4, 5)
        before = counters("timer")["frames"]
        check(bool(g.until(lambda: counters("timer")["frames"] >= before + 2, step=1, guard=60)), "timer shown again")
        g.run(64)  # (unpinned: as the game keeps it)
        check(counters("timer")["frames"] >= before + 32, "timer shown, unpinned: compared")
    finally:
        for at, value in saved:
            g.write(at, value)
    return covered


def keep_band(g):
    """The name window held open (its band): shown again when gone."""
    if not any(e["kind"] == "text_band" and e["live"] for e in g.call("hud", action="list")["elements"]):
        g.call("hud", action="show", kind="name_window", hold=True)


def tour_text_band(g, check, counters):
    """The name window's band (text box 7): its whole life (opening row by row, held, closing), then held with its
    box's fields written: from the top or the bottom, each grown edge, one to four lines, each icon."""
    import struct
    symbols = rood_rpc.symbols()
    box = symbols["vs_battle_textBoxes"] + 7 * 0x30
    covered, seen = [], set()

    def compared(label, frames=2):
        before = counters("text_band")["frames"]
        ok = g.until(lambda: counters("text_band")["frames"] >= before + frames, step=1, guard=60)
        elements = [e for e in g.call("hud", action="list")["elements"] if e["kind"] == "text_band" and e["live"]]
        seen.update((e["top"], e["edge"], e["lines"], e["settled"], e["icon"]) for e in elements)
        check(bool(ok) and elements, f"text_band {label}: compared ({len(elements)} live)")
        covered.append({"scenario": label, "bands": [{k: e[k] for k in ("box", "top", "edge", "lines", "settled",
                                                                        "icon")} for e in elements]})

    for index in (184, 1):  # a Break Art's name, another action's
        before = counters("text_band")["frames"]
        g.call("hud", action="show", kind="name_window", hold=False, index=index)
        ok = g.until(lambda: not any(e["kind"] == "text_band" and e["live"]
                                     for e in g.call("hud", action="list")["elements"])
                     and counters("text_band")["frames"] > before, step=1, guard=60)
        check(bool(ok) and counters("text_band")["frames"] >= before + 20,
              f"text_band: action {index}'s name window, its life ({counters('text_band')['frames'] - before} frames)")
        covered.append({"scenario": f"life {index}"})
    g.call("hud", action="show", kind="name_window", hold=True)
    compared("held")
    flags = struct.unpack("<I", g.read(box, 4))[0]
    y, lines = g.read(box + 0x16, 2), g.read(box + 0x21, 1)
    try:
        for top in (1, 0):
            for count in (1, 2, 3, 4):
                for icon in (0, 1, 2, 3, 4):
                    g.write(box + 0x16, struct.pack("<h", 0 if top else 1))
                    g.write(box + 0x21, bytes([count]))
                    g.write(box, struct.pack("<I", (flags & ~0xF00) | icon << 8))
                    compared(f"{'top' if top else 'bottom'}, {count} lines, icon {icon}")
    finally:
        g.write(box, struct.pack("<I", flags))
        g.write(box + 0x16, y)
        g.write(box + 0x21, lines)
        g.call("hud", action="clear")
    return covered


def targeting(g, on=True):
    """Targeting up (Circle, Circle in the save room: battle mode, then the target sphere; with no enemy about the
    information box says so, D_800EABAA 16) or left (Cross: out of it, then the weapon sheathed). The rows are the
    gate's to write (target_row)."""
    symbols = rood_rpc.symbols()

    def up():
        return int.from_bytes(g.read(symbols["D_800EB9B8"], 4), "little") != 0
    if up() != on:
        g.call("input", buttons=[], vsyncs=2)  # (a fixture's held L2 + R2 let go first)
        g.run(4)
    for _ in range(6):
        if up() == on and (on or not g.call("weapon_slots")["weapon_drawn"]):
            return True
        g.press("circle" if on else "cross", vsyncs=3, settle=40)
    return up() == on


ROW = 0x990  # D_800EB9B8's rows (unk990: 24 of 20 bytes)


def limb_names(g):
    """The parts' names as the rows show them (vs_battle_limbNames: guest addresses; '#' right-aligns)."""
    symbols = rood_rpc.symbols()
    pointer = 8 if pathlib.Path(rood_rpc.BINARY).read_bytes()[4] == 2 else 4  # (ELF class)
    names = []
    for i in range(16):
        at = int.from_bytes(g.read(symbols["vs_battle_limbNames"] + pointer * i, pointer), "little")
        if at >> 24 != 0x80:
            break
        names.append((at, g.read(at, 16).split(b"\0")[0].decode("latin-1")))
    return names


def write_row(g, i, state=1, selected=0, fade=8, age=0, x=248, y=32, bank=0, text=0):
    """Row i as func_800C5798 writes one (state 1 shown, 2 coming in from the right / going out to the left, 3 the
    other way; the 3D point the origin), and the fields the targeting steps (selected, the plate's fade, the line's
    age)."""
    import struct
    base = int.from_bytes(g.read(rood_rpc.symbols()["D_800EB9B8"], 4), "little")
    g.write(base + ROW + 20 * i, struct.pack("<BBBBhbbhhhhI", state, selected, fade, age, x, y, bank, 0, 0, 0, 0,
                                             text))


def row_state(g, i):
    base = int.from_bytes(g.read(rood_rpc.symbols()["D_800EB9B8"], 4), "little")
    return g.read(base + ROW + 20 * i, 1)[0]


def clear_rows(g):
    base = int.from_bytes(g.read(rood_rpc.symbols()["D_800EB9B8"], 4), "little")
    if base:
        g.write(base + ROW, bytes(24 * 20))


def tour_target_row(g, check, counters):
    """Every part's name on a row's whole life from either side (its slide in, the plate's fade from 8 to 0, its
    slide out), selected (the full plate, white) on both sides and banks, the list's rows at once."""
    covered = []
    if not check(targeting(g), "target_row: targeting up"):
        return covered
    names = limb_names(g)
    check(len(names) >= 6, f"target_row: the parts' names ({[n for _, n in names]})")
    fades, sides = set(), set()
    try:
        for k, (at, name) in enumerate(names):
            for side, (state, x, out) in enumerate(((2, 320, 3), (3, -72, 2))):
                clear_rows(g)
                bank = (k + side) & 1
                before = counters("target_row")["frames"]
                write_row(g, 0, state=state, x=x, y=32 + 11 * (k % 8), bank=bank, text=at)
                seen = set()

                def faded():  # (slid in, its plate's fade down to 0)
                    seen.update(e["fade"] for e in g.call("hud", action="list")["elements"]
                                if e["kind"] == "target_row" and e["live"])
                    return row_state(g, 0) == 1 and 0 in seen
                g.until(faded, step=1, guard=40)
                base = int.from_bytes(g.read(rood_rpc.symbols()["D_800EB9B8"], 4), "little")
                g.write(base + ROW, bytes([out]))  # (as func_800C56C0 sends them off)
                gone = g.until(lambda: row_state(g, 0) == 0, step=1, guard=40)
                frames = counters("target_row")["frames"] - before
                check(bool(gone) and frames >= 8, f"target_row {name!r} from the {('right', 'left')[side]}, bank "
                                                   f"{bank}: its life, {frames} frames compared")
                fades |= seen
                sides.add(side)
                covered.append({"name": name, "side": ("right", "left")[side], "bank": bank, "frames": frames})
        for side, x in ((0, 248), (1, -4)):
            for bank in (0, 1):
                clear_rows(g)
                before = counters("target_row")["frames"]
                for i in range(4):
                    write_row(g, i, selected=int(i == 1), x=x, y=32 + 11 * i, bank=bank ^ (i & 1),
                              text=names[1 + i % (len(names) - 1)][0])
                g.run(12)
                elements = [e for e in g.call("hud", action="list")["elements"] if e["kind"] == "target_row"
                            and e["live"]]
                frames = counters("target_row")["frames"] - before
                check(frames >= 16 and any(e["selected"] for e in elements),
                      f"target_row: four rows on the {('right', 'left')[side]}, bank {bank}, one selected: {frames} "
                      f"frames compared")
                covered.append({"rows": 4, "side": ("right", "left")[side], "bank": bank, "selected": 1})
        # deselected: the plate fades from the selected row's 7 to 0
        clear_rows(g)
        write_row(g, 0, selected=1, text=names[1][0])
        g.run(4)
        base = int.from_bytes(g.read(rood_rpc.symbols()["D_800EB9B8"], 4), "little")
        g.write(base + ROW + 1, b"\0")
        seen = set()
        g.until(lambda: seen.update(e["fade"] for e in g.call("hud", action="list")["elements"]
                                    if e["kind"] == "target_row" and e["live"]) or 0 in seen, step=1, guard=30)
        check(set(range(8)) <= seen, f"target_row: deselected, the plate faded 7..0 ({sorted(seen)})")
        covered.append({"deselected": sorted(seen)})
    finally:
        clear_rows(g)
        check(targeting(g, False), "target_row: targeting left")
    check(sides == {0, 1} and set(range(9)) <= fades, f"target_row: both sides, every fade 0..8 ({sorted(fades)})")
    return covered


LINE_AGES = [0, 1, 2, 3, 9, 16, 17, 18, 19, 25, 31, 33]  # (the sweep in; from 18 the second line, its count wrapped)


def tour_target_line(g, check, counters):
    """A selected row's leader lines from points about Ashley (in front, behind, to either side, above: the lines'
    every direction and odd and even lengths) to a row on either side, at the ages of their sweep (every age 0..33
    for the first point: the game's own run, 0x22 wrapping to 0x12 in its state 19)."""
    import struct
    covered, ages, sides = [], set(), set()
    if not check(targeting(g), "target_line: targeting up"):
        return covered
    names = limb_names(g)
    base = int.from_bytes(g.read(rood_rpc.symbols()["D_800EB9B8"], 4), "little")
    cx, cy, cz = struct.unpack("<hhh", g.read(base + 8, 6))  # (the sphere's centre: Ashley)
    points = [(cx + dx, cy + dy, cz + dz) for dx in (-768, 0, 768) for dy in (-512, 0) for dz in (-768, 0, 768)]
    try:
        for side, x in ((0, 248), (1, -4)):
            for k, point in enumerate(points):
                clear_rows(g)
                write_row(g, 0, selected=1, x=x, y=32 + 11 * (k % 8), bank=k & 1, text=names[1 + k % (len(names) - 1)][0])
                g.write(base + ROW + 8, struct.pack("<hhh", *point))
                before = counters("target_line")["frames"]
                for age in (range(34) if k == 0 else LINE_AGES):
                    g.write(base + ROW + 3, bytes([age]))
                    at = counters("target_line")["frames"]
                    if g.until(lambda: counters("target_line")["frames"] >= at + 1, step=1, guard=20):
                        e = next((e for e in g.call("hud", action="list")["elements"]
                                  if e["kind"] == "target_line" and e["live"]), None)
                        if e and e["age"] == age:
                            ages.add(age)
                frames = counters("target_line")["frames"] - before
                states = 34 if k == 0 else len(LINE_AGES)
                check(frames >= states, f"target_line from {point} to a row on the {('right', 'left')[side]}: "
                                        f"{frames} frames compared ({states} ages)")
                sides.add(side)
                covered.append({"point": point, "side": ("right", "left")[side], "frames": frames})
    finally:
        clear_rows(g)
        check(targeting(g, False), "target_line: targeting left")
    check(sides == {0, 1} and set(range(34)) <= ages, f"target_line: both sides, every age 0..33 "
                                                       f"(missing {sorted(set(range(34)) - ages)})")
    return covered


def keep_line(g):
    """The default and fallback checks' lines: targeting up, a selected row at age 20 (both lines) kept."""
    if not targeting(g):
        return
    if not any(e["kind"] == "target_line" and e["live"] for e in g.call("hud", action="list")["elements"]):
        write_row(g, 0, selected=1, age=20, text=limb_names(g)[1][0])


def keep_row(g):
    """The default and fallback checks' row: targeting up, a selected row kept (written when gone)."""
    if not targeting(g):
        return
    if not any(e["kind"] == "target_row" and e["live"] for e in g.call("hud", action="list")["elements"]):
        write_row(g, 0, selected=1, text=limb_names(g)[1][0])


KEEP = {"actor_word": keep_word, "emote": lambda g: keep_emotes(g), "text_band": keep_band,
        "target_row": keep_row, "target_line": keep_line}  # kinds without a show

EMOTES = [1, 2, 3, 4, 5, 6, 7, 0x10]  # the dots, the shout's '!', the heart, the surprise, '?' alone; 0x10 a balloon
# with no case of its own (func_80095C18's switch has none: the balloon alone)
OFFSETS = [(dx, dy, dz) for dx in (-6000, 0, 6000) for dy in (-4000, 0, 4000) for dz in (-6000, 0, 6000)]


def emote_actors(g):
    """The opening's actors with a record (D_800F4538, past Ashley): their positions' addresses."""
    symbols = rood_rpc.symbols()
    found = []
    for i in range(1, 16):
        actor = int.from_bytes(g.read(symbols["D_800F4538"] + PTR * i, PTR), "little")
        if actor:
            found.append((i, actor + 0x1C))  # (unk0.position)
    return found


def tour_emote(g, check, counters):
    """Each emote on every actor of the opening, both sides of each balloon (the side bits written either
    way), then the off-screen arrow: an emoting actor moved (its position written each frame) through a grid
    of places around and beyond the view, every direction it reaches compared; a far actor's sprite."""
    import struct
    symbols = rood_rpc.symbols()
    kinds_at, sides_at = symbols["D_800F2260"], symbols["D_800F2274"]
    saved = [(kinds_at, g.read(kinds_at, 16)), (sides_at, g.read(sides_at, 4)),
             (symbols["D_800F2270"], g.read(symbols["D_800F2270"], 2))]
    g.write(symbols["D_800F2270"], bytes(2))
    covered, seen = [], set()

    def live():
        return [e for e in g.call("hud", action="list")["elements"] if e["kind"] == "emote" and e["live"]]

    def compared(label, frames=2, keep=None):
        before = counters("emote")["frames"]

        def done():
            if keep:
                keep()
            return counters("emote")["frames"] >= before + frames
        ok = g.until(done, step=1, guard=60)
        elements = live()
        seen.update((e["draw"], e["emote"], e["side"], e["direction"]) for e in elements)
        check(bool(ok) and elements, f"emote {label}: compared ({len(elements)} live, "
                                     f"{counters('emote')['frames'] - before} frames)")
        covered.append({"scenario": label, "elements": [{k: e[k] for k in ("draw", "emote", "side", "z",
                                                                            "direction", "frame", "value")}
                                                        for e in elements]})
        return elements

    try:
        actors = emote_actors(g)
        check(len(actors) > 0, f"emote: the opening's actors {[i for i, _ in actors]}")
        for kind in EMOTES:
            for sides in (0, 0xFFFF):
                g.write(kinds_at, bytes([0] + [kind] * 15))
                g.write(sides_at, struct.pack("<I", sides))
                compared(f"kind {kind:#x}, side bits {sides:#x}")
        balloons = {(k, s) for d, k, s, _ in seen if d == "balloon"}
        check({1, 2, 3, 4, 5, 6} <= {k for k, _ in balloons} and any(d == "balloon" and k == 7 for d, k, _, _ in seen),
              f"emote: every kind drawn ({sorted(balloons)})")
        check({s for _, s in balloons} >= {0, 1, 2, 3, 4, 5}, f"emote: all six balloon sides drawn "
                                                             f"({sorted({s for _, s in balloons})})")
        # the arrow: kind 4 on one actor, moved
        i, at = actors[0]
        home = g.read(at, 6)
        g.write(kinds_at, bytes([0] + [4 if a == i else 0 for a in range(1, 16)]))
        x0, y0, z0 = struct.unpack("<hhh", home)
        try:
            for dx, dy, dz in OFFSETS:
                place = struct.pack("<hhh", max(-32768, min(32767, x0 + dx)), max(-32768, min(32767, y0 + dy)),
                                    max(-32768, min(32767, z0 + dz)))
                compared(f"actor {i} moved {dx}, {dy}, {dz}", keep=lambda: g.write(at, place))
        finally:
            g.write(at, home)
        directions = {d for draw, _, _, d in seen if draw == "arrow"}
        check(len(directions) > 0, f"emote: off-screen arrows drawn, directions {sorted(directions)}")
        # a far actor's sprite (kind with bit 8): only where the actor's motion gives it a frame
        g.write(kinds_at, bytes([0] + [8] * 15))
        g.run(8)
        far = [e for e in live() if e["draw"] == "far"]
        covered.append({"scenario": "far", "drawn": len(far)})
        print(f"note: far sprites drawn: {len(far)}", flush=True)
    finally:
        for address, value in saved:
            g.write(address, value)
    return covered, seen


def keep_emotes(g):
    symbols = rood_rpc.symbols()
    g.write(symbols["D_800F2270"], bytes(2))
    g.write(symbols["D_800F2260"], bytes([0] + [1] * 15))


def ability_icons_fixture(g, weapon_mode=False):
    g.call("settings", apply=f"qol_weapon_slots {int(weapon_mode)}")
    g.call("input", buttons=["l2", "r2"], vsyncs=2000)
    g.run(24)


def bind_test_weapon_slots(g):
    """Only the launched game's inventory: two occupied slots, the rest empty; caller restores it."""
    at = rood_rpc.symbols()["vs_main_inventory"]
    saved = g.read(at, 0x280)
    data = bytearray(saved)
    assigned = 0
    for i in range(8):
        data[i * 32 + 7] = 0
        if data[i * 32 + 1] and assigned < 2:
            assigned += 1
            data[i * 32 + 7] = assigned
    g.write(at, data)
    return at, saved, assigned


def tour_ability_icons(g, check, counters):
    """Nine emit groups, real C eligibility, animation, and weapon-slot side effects."""
    symbols = rood_rpc.symbols()
    actions = symbols["vs_main_actions"]
    saved_actions = g.read(actions, 256 * 52)
    mp_at = stats_address(g) + 4
    old_mp = g.read(mp_at, 2)
    status_at = stats_address(g) - 0x18 + 0x948
    old_status = g.read(status_at, 12)
    inventory_at, old_inventory, assigned = bind_test_weapon_slots(g)
    check(assigned > 0, "ability_icons occupied weapon-slot fixture")
    covered, seen_availability = [], set()

    def compared(label):
        before = counters("ability_icons")["frames"]
        check(bool(g.until(lambda: counters("ability_icons")["frames"] >= before + 9, step=1, guard=60)),
              "ability_icons " + label + ": nine groups compared")
        elements = [e for e in g.call("hud", action="list")["elements"] if e["kind"] == "ability_icons" and e["live"]]
        check({e["group"] for e in elements} == set(range(9)), "ability_icons all group keys live")
        check(all(e["anchor"] == 0 for e in elements), "ability_icons centre anchored")
        seen_availability.update(e["availability"] for e in elements if e["group"] != 8)
        covered.append({"scenario": label, "groups": [{k: e[k] for k in ("group", "availability", "animation", "offset")} for e in elements]})
        return elements

    try:
        for unlocked in (False, True):
            buf = bytearray(saved_actions)
            for i in range(256):
                buf[i * 52 + 13] = (buf[i * 52 + 13] & 127) | (128 if unlocked else 0)
            g.write(actions, buf)
            ability_icons_fixture(g)
            for mp in (0, 50):
                g.write(mp_at, mp.to_bytes(2, "little"))
                compared(f"unlocked {unlocked}, MP {mp}")
            if unlocked:
                g.write(status_at, (1 << 13).to_bytes(4, "little") + b"\xff" * 8)
                elements = compared("Ward disables Break Arts")
                check(next(e for e in elements if e["group"] == 7)["availability"] == 0x140,
                      "ability_icons disabled Break Arts from C")
                g.write(status_at, old_status)
            for index in range(1, 11):
                g.write(symbols["D_800EBCE8"], index.to_bytes(1, "little"))
                elements = compared(f"unlocked {unlocked}, entry animation {index - 1}")
                check(all(e["animation"] == index - 1 for e in elements), "ability_icons exact entry index")
            g.call("input", buttons=[], vsyncs=1)
            before = counters("ability_icons")["frames"]
            check(bool(g.until(lambda: g.read(symbols["D_800EBCE8"], 1) == b"\x0a", step=1, guard=90)),
                  "ability_icons animated hide completed")
            check(counters("ability_icons")["frames"] > before, "ability_icons hide frames compared")
            before = counters("ability_icons")["frames"]
            g.run(12)
            check(counters("ability_icons")["frames"] == before, "ability_icons hidden: no hook")
            covered.append({"scenario": f"unlocked {unlocked}, hide and hidden"})
        check({0, 0x140, 0x180} <= seen_availability,
              f"ability_icons locked/disabled/enabled observed: {sorted(seen_availability)}")
        g.write(actions, saved_actions)
        for mode in (False, True):
            ability_icons_fixture(g, mode)
            ws = g.call("weapon_slots")
            check(ws["overlay"] == int(mode) and ws["field_mode"] == 6,
                  f"ability_icons real weapon mode {mode}: overlay {ws['overlay']}, field {ws['field_mode']}")
            elements = compared(f"weapon-slot mode {mode}")
            if mode:
                check(all(e["availability"] == 0 for e in elements), "weapon mode C labels return zero; their packets are retained")
            g.call("input", buttons=[], vsyncs=1)
            g.run(40)
            covered.append({"scenario": f"weapon-slot mode {mode} exit"})
    finally:
        g.call("input", buttons=[], vsyncs=1)
        g.run(40)
        g.call("settings", apply="qol_weapon_slots 0")
        g.write(actions, saved_actions)
        g.write(mp_at, old_mp)
        g.write(status_at, old_status)
        g.write(inventory_at, old_inventory)
    return covered


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--card", default=str(default_save()))
    parser.add_argument("--out", help="logs and reports (default pc/build/tests/classic_parity)")
    parser.add_argument("--renderer", choices=["null", "gl", "vulkan"], default="null")
    parser.add_argument("--kind", default="status,chain,gauges,figure,status_icons,battle_mode,ability_icons,buff,damage,actor_word,timer,emote,text_frame,text_band,box_text,image,target_row,target_line,target_marker,menu_row,menu_cursor,menu_command,menu_tabs,menu_background,option_value", help="the kinds to check (comma-separated)")
    parser.add_argument("--candidate", action="store_true", help="explicitly opt in ability_icons before its default is gated")
    args = parser.parse_args()
    if not pathlib.Path(args.card).exists():
        print("SKIP: no memory card", args.card)
        return 77
    out = pathlib.Path(args.out) if args.out else OUT / "classic_parity"
    out.mkdir(parents=True, exist_ok=True)
    with card_guard(out / "cards", source=args.card) as cards:
        return run(out, cards.card1, args.renderer, [k for k in args.kind.split(",") if k], args.candidate)


OPENING = ("emote", "text_frame", "box_text")  # the kinds the opening shows (first_bubble): actors, the duke's talk bubble


def tour_text_frame(g, check, counters):
    """The talk bubble's frame: every shape the frames' table has, each flip and tail, written into the open box's
    fields (func_800CD3E4 reads them; the box's place and size stay the game's), then the next lines (the
    bubble closing, opening, moving)."""
    import struct
    symbols = rood_rpc.symbols()
    boxes, table = symbols["vs_battle_textBoxes"], symbols["D_800EB588"]
    covered, seen = [], set()

    def open_box():
        for i in range(8):
            flags, state = struct.unpack_from("<I", g.read(boxes + i * 0x30, 4))[0], struct.unpack(
                "<h", g.read(boxes + i * 0x30 + 0x1C, 2))[0]
            if state != 0 and (flags & 15) in (2, 7):
                return i, flags
        return None, None

    def compared(label, frames=2):
        before = counters("text_frame")["frames"]
        ok = g.until(lambda: counters("text_frame")["frames"] >= before + frames, step=1, guard=60)
        elements = [e for e in g.call("hud", action="list")["elements"] if e["kind"] == "text_frame" and e["live"]]
        seen.update((e["shape"], e["flip"], e["tail"]) for e in elements)
        check(bool(ok) and elements, f"text_frame {label}: compared ({len(elements)} live)")
        covered.append({"scenario": label, "boxes": [{k: e[k] for k in ("box", "box_x", "box_y", "box_w", "box_h",
                                                                        "shape", "flip", "tail")} for e in elements]})

    box, flags = open_box()
    if not check(box is not None, f"text_frame: a talk bubble open (box {box})"):
        return covered, seen
    shapes = [k for k in range(16) if int.from_bytes(g.read(table + k * PTR, PTR), "little")]
    try:
        for shape in shapes:
            for flip in range(4):
                for tail in (0, 1, 2, 3):
                    g.write(boxes + box * 0x30, struct.pack("<I", (flags & ~0xFFC0) | flip << 6 | shape << 8
                                                            | tail << 12 | (flags & 0xFFFF0000)))
                    compared(f"box {box} shape {shape} flip {flip} tail {tail}")
    finally:
        g.write(boxes + box * 0x30, struct.pack("<I", flags))
    check(len({sh for sh, _, _ in seen}) == len(shapes), f"text_frame: every shape drawn {sorted({sh for sh, _, _ in seen})}"
                                                         f" of {shapes}")
    for line in range(2):  # the next lines: the bubble closes, the next one opens and zooms in
        before = counters("text_frame")["frames"]
        g.press("circle", vsyncs=3, settle=0)
        g.run(300)
        check(counters("text_frame")["frames"] > before + 20, f"text_frame: line {line + 2}, its bubble's life compared "
                                                              f"({counters('text_frame')['frames'] - before} frames)")
        covered.append({"scenario": f"line {line + 2}"})
    return covered, seen


def tour_box_text(g, check, counters):
    """The talk bubble's text: the duke's line set (its zoom over), held; then the next lines typing out glyph by
    glyph (the typewriter's every step), the continuation arrow's frames; then each colour style and font table
    written into the open box's flags (the printer reads them)."""
    covered, seen = [], set()

    def compared(label, frames=2):
        before = counters("box_text")["frames"]
        ok = g.until(lambda: counters("box_text")["frames"] >= before + frames, step=1, guard=60)
        elements = [e for e in g.call("hud", action="list")["elements"] if e["kind"] == "box_text" and e["live"]]
        seen.update((e["box"], e["value"]) for e in elements)
        check(bool(ok) and elements, f"box_text {label}: compared ({[e['value'] for e in elements]} glyphs)")
        covered.append({"scenario": label, "glyphs": [e["value"] for e in elements]})

    import struct
    compared("the duke's line", frames=20)
    boxes = rood_rpc.symbols()["vs_battle_textBoxes"]
    box = next(e["box"] for e in g.call("hud", action="list")["elements"] if e["kind"] == "box_text" and e["live"])
    flags, brightness = struct.unpack("<I", g.read(boxes + box * 0x30, 4))[0], g.read(boxes + box * 0x30 + 0x1E, 1)
    try:  # (the printer's font table and colour style follow the box's kind; its brightness the box's selection)
        for kind, light in ((2, 0x40), (7, 0x80), (7, 0x40), (5, 0x80)):
            g.write(boxes + box * 0x30, struct.pack("<I", (flags & ~15) | kind))
            g.write(boxes + box * 0x30 + 0x1E, bytes([light]))
            compared(f"box {box} as kind {kind}, brightness {light:#x}")
    finally:
        g.write(boxes + box * 0x30, struct.pack("<I", flags))
        g.write(boxes + box * 0x30 + 0x1E, brightness)
    before = counters("box_text")["frames"]
    g.press("circle", vsyncs=3, settle=0)
    g.run(240)
    check(counters("box_text")["frames"] > before + 20, f"box_text: the next line typed out glyph by glyph and held "
                                                        f"({counters('box_text')['frames'] - before} frames)")
    covered.append({"scenario": "the next line, typed out"})
    return covered, seen


NEW_GAME = ("image",)  # the kinds New Game's opening shows before the first bubble: its cards


def run_new_game(out, env, check, waivers, kinds):
    """The images (func_800CCA90's tiled drawer): New Game's opening cards (the title, no card: Start, Circle). From
    the first card's first frame (a mark): the default and the fallback, state parity, then back to the mark and
    every frame of the cards' lives compared."""
    g = launch_at("title", card=str(out / "no-card.mcd"), fast=True, log=out / "game-new-game.log", extra_env=env)
    try:
        g.call("classic", parity=False)

        def counters(kind):
            return g.call("classic")["kinds"][kind]

        def images():
            return [e for e in g.call("hud", action="list")["elements"] if e["kind"] == "image" and e["live"]]
        g.press("start", vsyncs=4, settle=90)
        g.press("circle", vsyncs=3, settle=0)
        check(bool(g.until(lambda: images(), step=1, guard=120)), "image: the opening's first card drawn")
        g.pause()
        g.mark()
        default_and_fallback(g, "image", check)
        # state parity (§3.4) from the mark
        symbols = rood_rpc.symbols()
        pointer = 8 if pathlib.Path(rood_rpc.BINARY).read_bytes()[4] == 2 else 4
        masks = [[0x1F800000, 4]]
        for name, size in (("D_8005E0C0", 0x20000), ("D_80055C80", 0x822 * 4)):
            for i in range(2):
                address = int.from_bytes(g.read(symbols[name] + pointer * i, pointer), "little")
                masks.append([address, size])
        masks += [[a, n] for a, n, name in Symbols(rood_rpc.BINARY).rows if name == "last_vsync" and n == 2 * pointer]
        masks += packet_masks(symbols, pointer)
        g.rewind()
        drawn = g.call("hud", action="stats")["kinds"]["image"]["drawn"]
        g.digest("record", ticks=120, masks=masks)
        g.until(lambda: g.digest("result")["recorded"] >= 120, guard=120, what="the digest recorded")
        drawn = g.call("hud", action="stats")["kinds"]["image"]["drawn"] - drawn
        g.rewind()
        g.call("settings", apply="hud_classic_image 0")
        fallback = g.call("hud", action="stats")["kinds"]["image"]["fallback"]
        g.digest("compare")
        g.until(lambda: g.digest("result")["ticks"] >= 120, guard=120, what="the digest compared")
        result = g.digest("result")
        fallback = g.call("hud", action="stats")["kinds"]["image"]["fallback"] - fallback
        g.call("settings", apply="hud_classic_image 1")
        check(drawn > 0 and fallback > 0 and result.get("error") == 0 and result.get("first_tick") == -1
              and result.get("ticks") == result.get("recorded"),
              f"state parity image: {result.get('ticks')} of {result.get('recorded')} vsyncs the same (rood.classic "
              f"drew {drawn}, the game {fallback}; first difference {result.get('first_tick')} "
              f"{result.get('first_pages')})")
        # the gate: from the mark, the cards' lives
        g.rewind()
        g.call("classic", parity=True, reset=True)
        covered, seen = [], set()
        g.until(lambda: images(), step=1, guard=30)
        for card in range(3):
            before = counters("image")["frames"]
            ages = set()

            def gone():
                live = images()
                ages.update((e["image"], e["drawer"]) for e in live)
                return not live
            ok = g.until(gone, step=1, guard=120)
            frames = counters("image")["frames"] - before
            check(bool(ok) and frames > 10, f"image: card {card + 1}, its life: {frames} frames compared "
                                            f"({sorted(ages)})")
            seen |= ages
            covered.append({"scenario": f"card {card + 1}", "frames": frames, "images": sorted(map(list, ages))})
            if not g.until(lambda: images(), step=2, guard=30):
                break
        report = opening_report(g, check, waivers, "image", covered, seen)
        g.call("classic", parity=False)
        (out / "image.json").write_text(json.dumps(report, indent=1))
        print(f"report: {out / 'image.json'}: {report['frames']} frames, {report['states']} states, "
              f"{'green' if report['green'] else 'RED'}")
    finally:
        g.close()


def area_target(g):
    """Explosion's area target from the save room (the original menus: Triangle, Magick, Warlock, Explosion; the
    spells learned and MP full as ui_magick_smoke's prepare writes them): the sphere opened and the marker up."""
    import ui_magick_smoke
    symbols = rood_rpc.symbols()

    class Caster(ui_magick_smoke.Session):
        def __init__(self, game):
            self.name, self.out, self.shots, self.g, self.sym = "marker", None, False, game, symbols
    b = Caster(g)
    b.prepare()
    g.press("triangle", vsyncs=3, settle=10)
    b.wait_ready(0)
    b.nav(range(0, 10), 0)
    g.press("circle", vsyncs=3, settle=10)
    b.wait_ready(10)
    b.nav(range(10, 15), 10)
    g.press("circle", vsyncs=3, settle=10)
    b.wait_ready(20)
    g.run(10)
    warlock = [i for i in g.read(symbols["vs_battle_warlockSpellIds"], 18) if b.learned(i)]
    b.nav(range(20, 20 + len(warlock)), 20 + warlock.index(ui_magick_smoke.EXPLOSION))
    for _ in range(4):
        g.press("circle", vsyncs=3, settle=1)
        if b.wait(lambda: b.targeting() and b.menu() == ui_magick_smoke.CLOSED, 120, "", step=2, quiet=True) is not None:
            break
    return g.until(lambda: any(e["kind"] == "target_marker" and e["live"]
                               for e in g.call("hud", action="list")["elements"]), step=2, guard=120)


def run_marker(out, card, env, check, waivers):
    """The area target's marker (func_800C28AC), its own game from the save room: Explosion's target, the marker
    moved about (the d-pad: pitch and turn; the stick), every brightness step, locked (the first stage, or Square
    held) and with its brackets (Circle: the second stage); default, fallback and state parity there."""
    g = launch_at("save_room", card=card, fast=True, log=out / "game-marker.log", extra_env=env)
    kind = "target_marker"
    try:
        def counters():
            return g.call("classic")["kinds"][kind]

        def marker():
            return next((e for e in g.call("hud", action="list")["elements"] if e["kind"] == kind and e["live"]), None)
        g.call("classic", parity=True, reset=True)
        if not check(bool(area_target(g)), "target_marker: Explosion's area target up"):
            return
        covered, steps, places = [], {}, set()

        def watch(lock, vsyncs, buttons=()):
            before = counters()["frames"]
            for _ in range(vsyncs // 2):
                if buttons:
                    g.hold(list(buttons), 2)
                else:
                    g.run(2)
                e = marker()
                if e and e["lock"] == lock:
                    steps.setdefault(lock, set()).add(e["step"])
                    places.add((e["call_x"], e["call_y"]))
            frames = counters()["frames"] - before
            covered.append({"lock": lock, "buttons": list(buttons), "frames": frames})
            return frames
        for stage, lock in ((0, True), (1, False)):
            if stage == 1:
                g.press("circle", vsyncs=3, settle=4)  # (the second stage: the brackets)
            frames = watch(lock, 40)
            for buttons in (["up"], ["down"], ["left"], ["right"], ["up", "left"], ["down", "right"]):
                frames += watch(lock, 16, buttons)
            check(frames >= 60 and set(range(16)) <= steps.get(lock, set()),
                  f"target_marker {'locked' if lock else 'with its brackets'}: {frames} frames compared, steps "
                  f"{sorted(steps.get(lock, set()))}")
        frames = watch(True, 20, ["square"])  # (Square held: locked in the second stage too)
        check(frames >= 8, f"target_marker, Square held: locked, {frames} frames compared")
        check(len(places) >= 8, f"target_marker: moved about ({len(places)} places)")
        report = opening_report(g, check, waivers, kind, covered, set())
        g.call("classic", parity=False)
        default_and_fallback(g, kind, check)
        # state parity (§3.4): from a mark with the brackets up
        masks = state_masks(g)
        g.run(2)
        g.pause()
        g.mark()
        g.rewind()
        drawn = g.call("hud", action="stats")["kinds"][kind]["drawn"]
        g.digest("record", ticks=120, masks=masks)
        g.until(lambda: g.digest("result")["recorded"] >= 120, guard=120, what="the digest recorded")
        drawn = g.call("hud", action="stats")["kinds"][kind]["drawn"] - drawn
        g.rewind()
        g.call("settings", apply=f"hud_classic_{kind} 0")
        fallback = g.call("hud", action="stats")["kinds"][kind]["fallback"]
        g.digest("compare")
        g.until(lambda: g.digest("result")["ticks"] >= 120, guard=120, what="the digest compared")
        result = g.digest("result")
        fallback = g.call("hud", action="stats")["kinds"][kind]["fallback"] - fallback
        g.call("settings", apply=f"hud_classic_{kind} 1")
        check(drawn > 0 and fallback > 0 and result.get("error") == 0 and result.get("first_tick") == -1
              and result.get("ticks") == result.get("recorded"),
              f"state parity target_marker: {result.get('ticks')} of {result.get('recorded')} vsyncs the same "
              f"(rood.classic drew {drawn}, the game {fallback}; first difference {result.get('first_tick')} "
              f"{result.get('first_pages')})")
        (out / f"{kind}.json").write_text(json.dumps(report, indent=1))
        print(f"report: {out / (kind + '.json')}: {report['frames']} frames, {report['states']} states, "
              f"{'green' if report['green'] else 'RED'}")
    finally:
        g.close()


MENUS = ("menu_row", "menu_cursor", "menu_command", "menu_tabs", "menu_background",  # MAINMENU's shared frame
         "option_value")  # (and our Option pages' value column)
MENU_TOURED = ("menu_row", "menu_cursor", "menu_command", "menu_tabs", "menu_background",  # (Items: the tabs,
               "option_value")                                                            # the background)
ITEMS_ONLY = ("menu_tabs", "menu_background")  # (not on the Option screen: their default and fallback in Items)
OPTION_COMMAND, VANILLA_OPTIONS = 7, 9  # the top level's Option row (MENU8), its nine rows of the game's options


ITEMS_COMMAND, ITEMS_MENU = 3, 4  # the top level's Items row; its currentMenu (MENU3's screen)
INTRO_STATE = 0xAB  # vs_main_stateFlags.introState: under 3 (the prologue) Manage's Equip is unselectable
ITEM_CATEGORY = 0x3A  # D_800F4EE8.unk3A.currentItemCategory: the category + 1 (0: the Manage page, category 7)


def items_open(g, symbols):
    """Triangle, Items: MENU3 (its rows at rest)."""
    from menu_nav import top_command
    g.press("triangle", vsyncs=3, settle=30)
    top_command(g, symbols, ITEMS_COMMAND)
    for _ in range(5):  # (Circle once the top level takes it)
        g.press("circle", vsyncs=2, settle=2)
        if g.until(lambda: g.read(symbols["vs_battle_menuState"], 1)[0] & 0x3F == ITEMS_MENU, guard=10):
            break
    items_ready(g, symbols)


def items_live(g, symbols):
    """The live rows' ids (vs_battle_menuItems: 20.. a list, 32.. an action menu, ui_items_smoke's)."""
    p = int.from_bytes(g.read(symbols["vs_battle_menuItems"], PTR), "little")
    raw = g.read(p, 64 * 40) if p else b""
    return [i for i in range(len(raw) // 64) if raw[i * 64]]


def items_ready(g, symbols, limit=400):
    """Every live row idle (state 0 or 1) three frames in a row (ui_items_smoke's wait), MENU3 up."""
    calm = 0
    for _ in range(limit):
        p = int.from_bytes(g.read(symbols["vs_battle_menuItems"], PTR), "little")
        raw = g.read(p, 64 * 40) if p else b""
        live = [raw[i * 64] for i in range(len(raw) // 64) if raw[i * 64]]
        calm = calm + 1 if live and all(st <= 1 for st in live) else 0
        if calm >= 3:
            g.run(2)
            return
        g.run(1)
    raise RpcError(f"Items: the rows never came to rest (currentMenu {g.read(symbols['vs_battle_menuState'], 1)[0]:#x})")


def tour_items(g, symbols, toured, frames):
    """The Items screen (MENU3) through the original menus, for the shared frame's kinds: opened; the Manage page's
    Equip (its parts walked, the weapon's list in and out); every category in turn with R1 (the tab arrows; the
    category's list walked down past its end and back, the row's status view (Square) in and out, a row picked up and
    its actions walked, the Yes / No of its Discard opened and left on No); back round with L1; closed."""
    def press(button, settle=6):
        g.press(button, vsyncs=3, settle=settle)

    def category():
        return (g.read(symbols["D_800F4EE8"] + ITEM_CATEGORY, 1)[0] - 1) & 7

    def rows_now():  # (the live rows and their places: a status view slides them)
        p = int.from_bytes(g.read(symbols["vs_battle_menuItems"], PTR), "little")
        raw = g.read(p, 64 * 40) if p else b""
        return [(i, raw[i * 64 + 20:i * 64 + 24]) for i in range(len(raw) // 64) if raw[i * 64]]

    def at_rest():
        items_ready(g, symbols)
        if g.read(symbols["vs_battle_menuState"], 1)[0] & 0x3F != ITEMS_MENU:
            raise RpcError(f"Items: left MENU3 ({g.read(symbols['vs_battle_menuState'], 1)[0]:#x})")

    g.write(symbols["vs_main_settings"] + 1, b"\x00")  # (the cursor memory off: lists open on their first row)
    intro = g.read(symbols["vs_main_stateFlags"] + INTRO_STATE, 1)
    g.write(symbols["vs_main_stateFlags"] + INTRO_STATE, bytes([max(intro[0], 3)]))  # (Equip selectable)
    before = frames()
    items_open(g, symbols)
    toured("Items opened", before)
    for _ in range(9):
        if category() == 7:
            break
        press("r1", settle=10)
        at_rest()
    before = frames()
    press("circle", settle=20)  # Equip
    at_rest()
    for button in ("down",) * 6 + ("up",) * 6:
        press(button)
    press("circle", settle=20)  # the weapon's list
    at_rest()
    for button in ("down", "down", "up", "up"):
        press(button)
    press("cross", settle=20)
    at_rest()
    press("cross", settle=20)
    at_rest()
    toured("Items: Equip, its parts, the weapon's list", before)
    for step in range(8):  # weapons .. misc, then the Manage page again
        before = frames()
        press("r1", settle=10)
        at_rest()
        c, names = category(), None
        if c != 7 and any(20 <= i < 30 for i in items_live(g, symbols)):  # (an empty category: Cross would leave)
            for button in ("down",) * 10 + ("up",) * 10:
                press(button, settle=4)
            rows = rows_now()
            press("square", settle=20)  # the status view (refused in some categories: nothing changes)
            g.run(30)
            if rows_now() != rows:
                press("cross", settle=20)
                at_rest()
            press("circle", settle=10)  # picked up
            at_rest()
            press("circle", settle=10)  # its actions
            at_rest()
            for button in ("down",) * 4 + ("up",) * 4:
                press(button)
            actions = str(repl(g, "rood.classic", "local t = {} for _, r in ipairs(rood.game.menu().rows) do "
                               "if r.id >= 32 and r.state ~= 'inactive' then t[#t + 1] = r.id .. '=' .. r.text end end "
                               "return table.concat(t, '|')")).strip('"').split("|")
            names = [a.split("=", 1)[1].strip().lower()
                     for a in sorted((a for a in actions if "=" in a), key=lambda a: int(a.split("=")[0]))]
            if "discard" in names:
                for _ in range(names.index("discard")):  # (the actions open on their first row)
                    press("down")
                press("circle", settle=10)  # Discard: the Yes / No (on No)
                g.run(20)
                press("cross", settle=10)  # left on No
                g.run(20)
            at_rest()
            if any(i >= 32 for i in items_live(g, symbols)):  # (the actions again: Cross to the list)
                press("cross", settle=10)
                at_rest()
        print(f"Items: category {c} toured (actions {names if c != 7 else None})", flush=True)  # (progress)
        toured(f"Items: category {c}: its list, status view, actions, Discard's Yes / No", before, category=c)
    before = frames()
    for _ in range(8):
        press("l1", settle=10)
        at_rest()
    toured("Items: the categories back round with L1", before)
    before = frames()
    press("triangle", settle=60)
    g.until(lambda: g.read(symbols["vs_battle_menuState"], 1)[0] == 0x3F, guard=600, what="Items closed")
    toured("Items closed", before)
    g.write(symbols["vs_main_stateFlags"] + INTRO_STATE, intro)


def run_menus(out, card, env, check, waivers, kinds):
    """MAINMENU's shared frame through the game's Option screen (MENU8 and our pages; Rename excluded), its own game
    from the save room (the original menus): the menu opened; the list walked down through every entry (the
    game's nine rows, our pages, the scroll) and back; each of the nine rows' flyouts opened, moved through, left;
    each of our pages opened and walked through to its end (the scroll arrows), Display's Scaling flyout, the
    Fullscreen mode's "Keep these settings?" (KEEP / REVERT: the test modes); the menu closed. Then the default and
    the fallback per kind, state parity from a mark as the list opens."""
    from menu_nav import top_command
    env = dict(env, ROOD_TEST_FULLSCREEN_MODES="1920x1080@60,1280x720@60")
    g = launch_at("save_room", card=card, fast=True, log=out / "game-menus.log", extra_env=env)
    symbols = rood_rpc.symbols()
    covered = []
    try:
        def opt():
            return g.call("options")["classic"]

        def wait(screen, limit=600):
            for _ in range(limit):
                o = opt()
                if o["screen"] == screen and o["ready"]:
                    return o
                g.run(1)
            raise RpcError(f"options screen {screen}: {json.dumps(opt())[:300]}")

        def press(button, settle=2):
            g.press(button, vsyncs=2, settle=settle)

        def frames():
            k = g.call("classic")["kinds"]
            return {kind: k[kind]["frames"] for kind in MENUS}

        def toured(label, before, **extra):
            after = frames()
            covered.append({"scenario": label, **{k: after[k] - before[k] for k in MENUS if after[k] > before[k]},
                            **extra})

        def list_to(index):
            for _ in range(60):
                o = wait("list")
                if o["list_focus"] == index:
                    return o
                press("down" if o["list_focus"] < index else "up")
            raise RpcError(f"the Option list's entry {index}")

        def page_to(row_id):
            for _ in range(80):
                o = wait("page")
                if o["focus_id"] == row_id:
                    return o
                press("down")
            raise RpcError(f"row {row_id}")

        g.call("classic", parity=True, reset=True)
        before = frames()
        g.press("triangle", vsyncs=3, settle=30)
        top_command(g, symbols, OPTION_COMMAND)
        press("circle")
        o = wait("list")
        toured("the menu opened, the Option list in", before)
        entries = o["entries"]
        total = VANILLA_OPTIONS + len(entries)
        before = frames()
        for _ in range(total):  # down through every entry (the list scrolls), wrapping to the top
            press("down")
            wait("list")
        for _ in range(3):
            press("up")
            wait("list")
        toured(f"the list walked: {total} entries down and back", before, entries=total)
        for row in range(VANILLA_OPTIONS):  # each of the game's own options: its flyout
            list_to(row)
            before = frames()
            press("circle", settle=30)
            for button in ("down", "down", "up"):
                press(button, settle=6)
            press("cross", settle=4)
            wait("list")
            toured(f"option {row}'s flyout: in, moved through, out", before, row=row)
        for entry in entries:
            if not entry.startswith("rood.options/"):
                continue
            list_to(VANILLA_OPTIONS + entries.index(entry))
            before = frames()
            press("circle")
            o = wait("page")
            for _ in range(len(o["rows"]) + 1):  # to its end (the scroll arrows) and around
                press("down")
                wait("page")
            if entry == "rood.options/display":
                page_to("aspect")
                press("circle")
                wait("flyout")
                for button in ("down", "up"):
                    press(button, settle=4)
                    wait("flyout")
                press("cross")
                wait("page")
                def pick(row_id, index):
                    """Circle on the row, its flyout's choice `index`, Circle (options_confirm_smoke's way)."""
                    page_to(row_id)
                    r = next(r for r in wait("page")["rows"] if r["id"] == row_id)
                    press("circle")
                    wait("flyout")
                    for _ in range((index - r["index"]) % r["count"]):
                        press("down")
                    press("circle")
                    return r["index"]
                window = pick("window_mode", 2)  # Fullscreen (the exclusive modes' row then asks)
                wait("page")
                mode = pick("fullscreen_mode", 1)
                wait("confirm")
                press("down", settle=6)  # REVERT
                press("up", settle=6)    # KEEP
                press("cross")           # (Cross: reverted)
                wait("page")
                check(next(r for r in wait("page")["rows"] if r["id"] == "fullscreen_mode")["index"] == mode,
                      "menus: Keep these settings? toured, reverted")
                pick("window_mode", window)
                wait("page")
            press("cross")
            wait("list")
            toured(f"page {entry}: in, every row, out", before, page=entry)
        before = frames()
        press("triangle", settle=60)
        toured("the menu closed", before)
        g.until(lambda: g.read(symbols["vs_battle_menuState"], 1)[0] == 0x3F, guard=600, what="the menu closed")
        g.run(30)
        tour_items(g, symbols, toured, frames)
        reports = {kind: opening_report(g, check, waivers, kind, covered, set()) for kind in kinds
                   if kind in MENU_TOURED}
        for kind in kinds:
            if kind not in MENU_TOURED:
                c = g.call("classic")["kinds"][kind]
                check(c["mismatched"] == 0 and c["skipped"] == 0,
                      f"{kind} (not toured here): {c['frames']} frames compared, {c['mismatched']} mismatched")
        g.call("classic", parity=False)
        toured_kinds = [k for k in kinds if k in MENU_TOURED]

        def state_proof(label, expect):
            """§3.4 from the mark: 120 vsyncs with rood.classic drawing, then with the game drawing. (Masked too: the
            Option pages' help clock, classic_options.c's help.since: the host's seconds when a help box was set.)"""
            masks = state_masks(g) + [[a + 400, 8] for a, n, name in Symbols(rood_rpc.BINARY).rows
                                      if name == "help" and n == 408]
            g.rewind()
            drawn = {k: g.call("hud", action="stats")["kinds"][k]["drawn"] for k in toured_kinds}
            g.digest("record", ticks=120, masks=masks)
            g.until(lambda: g.digest("result")["recorded"] >= 120, guard=120, what="the digest recorded")
            drawn = {k: g.call("hud", action="stats")["kinds"][k]["drawn"] - drawn[k] for k in toured_kinds}
            g.rewind()
            g.call("settings", apply=[f"hud_classic_{k} 0" for k in toured_kinds])
            fallback = {k: g.call("hud", action="stats")["kinds"][k]["fallback"] for k in toured_kinds}
            g.digest("compare")
            g.until(lambda: g.digest("result")["ticks"] >= 120, guard=120, what="the digest compared")
            result = g.digest("result")
            fallback = {k: g.call("hud", action="stats")["kinds"][k]["fallback"] - fallback[k] for k in toured_kinds}
            g.call("settings", apply=[f"hud_classic_{k} 1" for k in toured_kinds])
            check(all(drawn[k] > 0 and fallback[k] > 0 for k in toured_kinds if k in expect) and result.get("error") == 0
                  and result.get("first_tick") == -1 and result.get("ticks") == result.get("recorded"),
                  f"state parity menus, {label}: {result.get('ticks')} of {result.get('recorded')} vsyncs the same "
                  f"(rood.classic drew {drawn}, the game {fallback}; first difference {result.get('first_tick')} "
                  f"{result.get('first_pages')})")

        # the default and the fallback, then the state proofs: the Option list at rest (the hand pulsing), and
        # Display's rows sliding in one a frame with its help (a mark just after Circle on it)
        g.until(lambda: g.read(symbols["vs_battle_menuState"], 1)[0] == 0x3F, guard=600, what="the menu closed")
        g.run(30)
        g.press("triangle", vsyncs=3, settle=30)
        top_command(g, symbols, OPTION_COMMAND)
        for _ in range(5):  # (Circle once the top level takes it)
            press("circle")
            if g.until(lambda: g.read(symbols["vs_battle_menuState"], 1)[0] & 0x3F == 8, guard=5):
                break
        wait("list")
        g.pause()
        g.mark()
        for kind in toured_kinds:
            if kind != "option_value" and kind not in ITEMS_ONLY:  # (no values in the list: on a page, below)
                g.rewind()
                default_and_fallback(g, kind, check)
        state_proof("the Option list at rest", ("menu_row", "menu_cursor", "menu_command"))
        g.rewind()
        list_to(VANILLA_OPTIONS + entries.index("rood.options/display"))
        press("circle", settle=0)
        g.mark()
        if "option_value" in toured_kinds:
            default_and_fallback(g, "option_value", check)
        state_proof("Display's rows coming in", [k for k in toured_kinds if k not in ITEMS_ONLY])
        # Items: the default and the fallback of every frame kind, the state proof at its list at rest (the tabs'
        # arrows bobbing, the background up)
        g.rewind()
        for _ in range(8):  # (out of Display's page, the list, the menu)
            if g.read(symbols["vs_battle_menuState"], 1)[0] == 0x3F:
                break
            g.press("cross" if g.read(symbols["vs_battle_menuState"], 1)[0] & 0x3F == 8 else "triangle", vsyncs=3,
                    settle=60)
        g.until(lambda: g.read(symbols["vs_battle_menuState"], 1)[0] == 0x3F, guard=600, what="the menu closed")
        g.run(30)
        items_open(g, symbols)
        g.press("r1", vsyncs=3, settle=10)  # (a category's list: the tab arrows)
        items_ready(g, symbols)
        g.pause()
        g.mark()
        items_kinds = [k for k in toured_kinds if k != "option_value"]
        for kind in items_kinds:
            g.rewind()
            default_and_fallback(g, kind, check)
        toured_kinds[:] = items_kinds
        state_proof("the Items list at rest", items_kinds)
        for kind, report in reports.items():
            (out / f"{kind}.json").write_text(json.dumps(report, indent=1))
            print(f"report: {out / (kind + '.json')}: {report['frames']} frames, {report['states']} states, "
                  f"{'green' if report['green'] else 'RED'}")
    finally:
        g.close()


def opening_report(g, check, waivers, kind, covered, extra):
    c = g.call("classic")["kinds"][kind]
    declared = sorted(n for n in str(repl(g, "rood.classic", f"return table.concat(M.look.overrides.{kind} or {{}}, ',')"))
                      .strip('"').split(",") if n)
    waived = waivers.get(kind, {})
    allowed = {f for w in waived.values() for f in w.get("fields", [])}
    unwaived = {f: n for f, n in c["fields"].items() if f not in allowed}
    check(c["frames"] > 0 and c["skipped"] == 0,
          f"{kind}: {c['frames']} frames compared, {c['skipped']} skipped ({c['skip'] or 'none'})")
    check(not unwaived, f"{kind}: {c['matched']} matched, {c['mismatched']} mismatched; unwaived fields "
                        f"{unwaived or 'none'}" + (f"; first {json.dumps(c.get('first'))}" if unwaived else ""))
    check(sorted(waived) == declared, f"{kind}: overrides declared {declared} = waived {sorted(waived)}")
    return {"kind": kind, "frames": c["frames"], "matched": c["matched"], "mismatched": c["mismatched"],
            "skipped": c["skipped"], "fields": c["fields"], "first": c.get("first"), "waived": dict(waived),
            "declared": declared, "coverage": covered, "states": len(covered), "drawn": sorted(map(list, extra)),
            "green": c["frames"] > 0 and c["skipped"] == 0 and not unwaived}


def run_opening(out, env, check, waivers, kinds):
    """The kinds the save room does not show: the emotes (actors on screen) and the talk bubbles' frames, at the
    opening (the first_bubble checkpoint: the duke's bubble zooms in, his line waits for a button), its own game;
    the gate, the default and the fallback, state parity there."""
    # (no card: the title's cursor then rests on New Game, the checkpoint's way in)
    g = launch_at("first_bubble", card=str(out / "no-card.mcd"), fast=True, log=out / "game-opening.log",
                  extra_env=env)
    try:
        g.call("classic", parity=True, reset=True)

        def counters(kind):
            return g.call("classic")["kinds"][kind]
        g.run(200)  # (the bubble's zoom: every frame compared)
        tours = {}
        if "emote" in kinds:
            tours["emote"] = tour_emote(g, check, counters)
        if "text_frame" in kinds:
            check(counters("text_frame")["frames"] >= 20, f"text_frame: the bubble's zoom compared "
                                                          f"({counters('text_frame')['frames']} frames)")
            tours["text_frame"] = tour_text_frame(g, check, counters)
        if "box_text" in kinds:
            tours["box_text"] = tour_box_text(g, check, counters)
        reports = {kind: opening_report(g, check, waivers, kind, *tours[kind]) for kind in tours}
        g.call("classic", parity=False)
        symbols = rood_rpc.symbols()
        for kind in kinds:
            if kind == "emote":
                keep_emotes(g)
            default_and_fallback(g, kind, check)
        if "text_frame" in kinds:  # the vector talk bubbles (an option) redraw rood.classic's copies as the game's
            g.call("graphics", ui_bubbles="vector")
            b0 = g.call("ui_bubbles")
            g.run(20)
            b1 = g.call("ui_bubbles")
            g.call("graphics", ui_bubbles="original")
            drawn = g.call("hud", action="stats")["kinds"]["text_frame"]
            check(b1["verified"] >= b0["verified"] + 8 and b1["mismatched"] == b0["mismatched"] and drawn["honoured"],
                  f"text_frame: ui_bubbles vector over rood.classic's frames: {b1['verified'] - b0['verified']} "
                  f"verified, {b1['mismatched'] - b0['mismatched']} mismatched")
        # state parity (§3.4) here: from one mark, rood.classic drawing, then the game
        pointer = 8 if pathlib.Path(rood_rpc.BINARY).read_bytes()[4] == 2 else 4
        masks = [[0x1F800000, 4]]
        for name, size in (("D_8005E0C0", 0x20000), ("D_80055C80", 0x822 * 4)):
            for i in range(2):
                address = int.from_bytes(g.read(symbols[name] + pointer * i, pointer), "little")
                masks.append([address, size])
        masks += [[a, n] for a, n, name in Symbols(rood_rpc.BINARY).rows if name == "last_vsync" and n == 2 * pointer]
        masks += packet_masks(symbols, pointer)
        runs = ([("emote", k) for k in (1, 4, 5) if "emote" in kinds] + [("text_frame", 0)] * ("text_frame" in kinds)
                + [("box_text", 0)] * ("box_text" in kinds))
        for kind, emote in runs:
            g.write(symbols["D_800F2270"], bytes(2))
            g.write(symbols["D_800F2260"], bytes([0] + [emote] * 15))
            g.run(4)
            g.pause()
            g.mark()
            g.rewind()
            drawn = g.call("hud", action="stats")["kinds"][kind]["drawn"]
            g.digest("record", ticks=120, masks=masks)
            g.until(lambda: g.digest("result")["recorded"] >= 120, guard=120, what="the digest recorded")
            drawn = g.call("hud", action="stats")["kinds"][kind]["drawn"] - drawn
            g.rewind()
            g.call("settings", apply=f"hud_classic_{kind} 0")
            fallback = g.call("hud", action="stats")["kinds"][kind]["fallback"]
            g.digest("compare")
            g.until(lambda: g.digest("result")["ticks"] >= 120, guard=120, what="the digest compared")
            result = g.digest("result")
            fallback = g.call("hud", action="stats")["kinds"][kind]["fallback"] - fallback
            g.call("settings", apply=f"hud_classic_{kind} 1")
            check(drawn > 0 and fallback > 0 and result.get("error") == 0 and result.get("first_tick") == -1
                  and result.get("ticks") == result.get("recorded"),
                  f"state parity {kind} {emote}: {result.get('ticks')} of {result.get('recorded')} vsyncs the same "
                  f"(rood.classic drew {drawn}, the game {fallback}; first difference {result.get('first_tick')} "
                  f"{result.get('first_pages')})")
        for kind, report in reports.items():
            (out / f"{kind}.json").write_text(json.dumps(report, indent=1))
            print(f"report: {out / (kind + '.json')}: {report['frames']} frames, {report['states']} states, "
                  f"{'green' if report['green'] else 'RED'}")
    finally:
        g.close()


def run(out, card, renderer, kinds, candidate=False):
    failures = []

    def check(ok, message):
        print(("ok:   " if ok else "FAIL: ") + message, flush=True)
        if not ok:
            failures.append(message)
        return ok

    plugins = out / "plugins"  # (no player plugins: only the shipped ones)
    shutil.rmtree(plugins, ignore_errors=True)
    plugins.mkdir(parents=True)
    shutil.rmtree(out / "plugin_data", ignore_errors=True)
    settings = out / "settings.cfg"
    settings.write_text("ui_menus 0\nui_text font\naspect 16:9\ninterpolate 0\n")
    env = {"ROOD_SETTINGS": str(settings), "ROOD_PLUGINS": str(plugins), "ROOD_PLUGIN_DATA": str(out / "plugin_data"),
           "ROOD_PLUGINS_SHIPPED": str(ROOT / "pc/plugins"), "ROOD_CLASSIC_PARITY": "1", "ROOD_DETERMINISTIC": "1"}
    if renderer == "null":
        env.update({"ROOD_RENDERER": "null", "SDL_VIDEO_DRIVER": "invalid-null-classic-parity"})
        # (the run's save states are made for its own renderer: boot to the checkpoint instead)
        if os.environ.get("ROOD_RENDERER") != "null":
            os.environ["ROOD_TEST_SNAPSHOTS"] = "0"
    elif renderer == "vulkan":
        env["ROOD_RENDERER"] = "vulkan"
    waivers = tomllib.loads((ROOT / "pc/tests/classic/waivers.toml").read_text())
    if "image" in kinds:
        run_new_game(out, env, check, waivers, ["image"])
        kinds = [k for k in kinds if k != "image"]
        if not kinds:
            print(f"{'PASS' if not failures else 'FAIL'}: classic parity ({len(failures)} failures)")
            return 1 if failures else 0
    if "target_marker" in kinds:
        run_marker(out, card, env, check, waivers)
        kinds = [k for k in kinds if k != "target_marker"]
        if not kinds:
            print(f"{'PASS' if not failures else 'FAIL'}: classic parity ({len(failures)} failures)")
            return 1 if failures else 0
    if any(k in MENUS for k in kinds):
        run_menus(out, card, env, check, waivers, [k for k in kinds if k in MENUS])
        kinds = [k for k in kinds if k not in MENUS]
        if not kinds:
            print(f"{'PASS' if not failures else 'FAIL'}: classic parity ({len(failures)} failures)")
            return 1 if failures else 0
    if any(k in OPENING for k in kinds):
        run_opening(out, env, check, waivers, [k for k in kinds if k in OPENING])
        kinds = [k for k in kinds if k not in OPENING]
        if not kinds:
            print(f"{'PASS' if not failures else 'FAIL'}: classic parity ({len(failures)} failures)")
            return 1 if failures else 0
    g = launch_at("save_room", card=card, fast=True, log=out / "game.log", extra_env=env)
    try:
        plugin = g.lua_plugins().get("rood.classic")
        if not check(plugin and plugin.get("state") == "loaded", f"rood.classic loaded ({plugin and plugin.get('state')})"):
            return 1
        if candidate:
            g.call("settings", apply="hud_classic_ability_icons 1")
        g.call("classic", parity=True, reset=True)
        check(g.call("classic")["parity"], "the parity mode is on")

        def counters(kind):
            return g.call("classic")["kinds"][kind]

        waivers = tomllib.loads((ROOT / "pc/tests/classic/waivers.toml").read_text())
        declared = {}  # M.look.overrides as "kind=a,b;kind=..."
        for item in str(repl(g, "rood.classic", "local t = {} for k, v in pairs(M.look.overrides) do "
                                                  "t[#t + 1] = k .. '=' .. table.concat(v, ',') end "
                                                  "return table.concat(t, ';')")).strip('"').split(";"):
            if "=" in item:
                key, names = item.split("=", 1)
                declared[key] = [n for n in names.split(",") if n]
        reports = {}
        for kind in kinds:
            covered = []
            ages = set()
            if kind == "gauges":
                covered = tour_gauges(g, check, counters)
            elif kind == "figure":
                covered = tour_figure(g, check, counters)
            elif kind == "status_icons":
                covered = tour_status_icons(g, check, counters)
            elif kind == "battle_mode":
                covered = tour_battle_mode(g, check, counters)
            elif kind == "ability_icons":
                covered = tour_ability_icons(g, check, counters)
            elif kind == "buff":
                covered = tour_buff(g, check, counters)
            elif kind == "actor_word":
                covered = tour_actor_word(g, check, counters)
            elif kind == "timer":
                covered = tour_timer(g, check, counters)
            elif kind == "text_band":
                covered = tour_text_band(g, check, counters)
            elif kind == "target_row":
                covered = tour_target_row(g, check, counters)
            elif kind == "target_line":
                covered = tour_target_line(g, check, counters)
            for show, text in states(kind):
                # held (rood.dev.show: the game's own spawner, the age pinned) until the gate compared two of
                # its frames showing this element's text
                g.call("hud", action="show", kind=kind, hold=True, age=10, **show)
                before = counters(kind)["frames"]
                ok = g.until(lambda: (lambda c: c["frames"] >= before + 2 and c["text"] == text)(counters(kind)),
                             guard=60)
                if not check(bool(ok), f"{kind} {text}, held: compared ({counters(kind)})"):
                    continue
                # then its whole life played out (slide in, held, slide out): every frame compared
                g.call("hud", action="clear")
                g.call("hud", action="show", kind=kind, hold=False, **show)
                seen, before = set(), counters(kind)["frames"]

                def gone():
                    live = [e for e in g.call("hud", action="list")["elements"]
                            if e["kind"] == kind and e["text"] == text and e["live"] and not e["synthetic"]]
                    seen.update(e["age"] for e in live)
                    return not live and seen
                ok = g.until(gone, step=1, guard=60)
                frames = counters(kind)["frames"] - before
                check(bool(ok) and frames >= len(seen), f"{kind} {text}, its life: {frames} frames compared, ages "
                                                      f"{min(seen) if seen else '-'}..{max(seen) if seen else '-'}")
                ages |= seen
                covered.append({**show, "text": text, "ages": sorted(seen)})
            g.call("hud", action="clear")
            slides = SLIDES.get(kind, set())
            check(slides <= ages, f"{kind}: its slides covered" + (f" (ages {sorted(slides - ages)} missing)"
                                                                     if not slides <= ages else ""))
            c = counters(kind)
            waived = waivers.get(kind, {})
            allowed = {f for w in waived.values() for f in w.get("fields", [])}
            unwaived = {f: n for f, n in c["fields"].items() if f not in allowed}
            check(c["frames"] > 0 and c["skipped"] == 0,
                  f"{kind}: {c['frames']} frames compared, {c['skipped']} skipped ({c['skip'] or 'none'})")
            check(not unwaived, f"{kind}: {c['matched']} matched, {c['mismatched']} mismatched; unwaived fields "
                                f"{unwaived or 'none'}" + (f"; first {json.dumps(c.get('first'))}" if unwaived else ""))
            names = sorted((declared or {}).get(kind) or [])
            check(names == sorted(waived), f"{kind}: overrides declared {names} = waived {sorted(waived)}")
            reports[kind] = {"kind": kind, "frames": c["frames"], "matched": c["matched"],
                             "mismatched": c["mismatched"], "skipped": c["skipped"], "fields": c["fields"],
                             "first": c.get("first"), "waived": {k: v for k, v in waived.items()},
                             "declared": names, "coverage": covered, "states": len(covered),
                             "green": c["frames"] > 0 and c["skipped"] == 0 and not unwaived}
            if kind == "ability_icons":
                reports[kind]["capture_unit"] = "group (nine per display frame)"
                reports[kind]["display_frames"] = c["frames"] // 9
        for kind in OPENING:  # (the save room shows some too: the name window's text; each compared here as well)
            c = counters(kind)
            check(c["mismatched"] == 0 and c["skipped"] == 0,
                  f"{kind} in the save room: {c['frames']} frames compared, {c['mismatched']} mismatched, "
                  f"{c['skipped']} skipped")
        g.call("classic", parity=False)
        check(not g.call("classic")["parity"], "the parity mode is off")

        ability_icons_fixture(g)
        battle_mode_fixture(g)  # active phase for fallback and both same-mark state proofs
        status_icons_fixture(g)  # an active carousel for fallback and the same-mark state proof
        timer_at = rood_rpc.symbols()["vs_battle_lowerScreenUiState"]
        timer_shown = g.read(timer_at, 1)
        timer_fixture(g, 12, 34, 56)  # the timer up for fallback and the state proofs
        for kind in kinds:
            default_and_fallback(g, kind, check)
        if any(k in TARGETING for k in kinds):
            target_state_parity(g, check)
        check(targeting(g, False), "targeting left")
        ability_icons_fixture(g)  # (again: leaving battle mode ended them)
        battle_mode_fixture(g)
        status_icons_fixture(g)
        state_parity(g, check)
        # The doubled tick path and supplemental-glyph carousel get the same state proof too.
        speed_at = rood_rpc.symbols()["vs_gametime_tickspeed"]
        old_speed = g.read(speed_at, 4)
        inventory_at, old_inventory, assigned = bind_test_weapon_slots(g)
        check(assigned > 0, "state parity weapon-slot names fixture occupied")
        try:
            g.write(speed_at, (4).to_bytes(4, "little"))
            status_icons_fixture(g, 0x1FE00000, phase=12, previous=16, current=17, next_icon=18)
            ability_icons_fixture(g, weapon_mode=True)
            state_parity(g, check)
            ability_icons_fixture(g, weapon_mode=True)
            state_parity(g, check, ability_hold=False)  # actual animation out, including C weapon-slot side effects
        finally:
            g.write(speed_at, old_speed)
            g.write(inventory_at, old_inventory)
            g.write(timer_at, timer_shown)
        report_dir = out
        for kind, report in reports.items():
            (report_dir / f"{kind}.json").write_text(json.dumps(report, indent=1))
            measured = (f"{report['frames']} hook comparisons / {report['display_frames']} display frames"
                        if kind == "ability_icons" else f"{report['frames']} frames")
            print(f"report: {report_dir / (kind + '.json')}: {measured}, {report['states']} states, "
                  f"{'green' if report['green'] else 'RED'}")
    finally:
        g.close()
    print(f"{'PASS' if not failures else 'FAIL'}: classic parity ({len(failures)} failures)")
    return 1 if failures else 0


def repl(g, plugin, code):
    """A value from the plugin's sandbox (its module is M), as JSON."""
    reply = g.repl(op="eval", plugin=plugin, code=code)
    values = reply.get("values") or reply.get("results") or []
    if not reply.get("ok", True) or not values:
        raise RpcError(f"repl {code}: {reply}")
    value = values[0]
    return value.get("value", value) if isinstance(value, dict) and "value" in value else value


SHOW = {"status": {"timing": "slow", "age": 10}, "chain": {"count": 3, "age": 40},
        "buff": {"slot": "WEAPON", "stat": "HUMAN", "value": 1, "sign": 1, "age": 10},
        "damage": {"pool": "hp", "sign": -1, "value": 57, "age": 10}}


def default_and_fallback(g, kind, check):
    """The parity mode off: rood.classic draws the kind by default; with its setting off, a draw that
    raises, or the plugin off, the game's own drawing each time."""
    def stats():
        if kind in KEEP:
            KEEP[kind](g)
        return g.call("hud", action="stats")["kinds"][kind]

    if kind in SHOW:  # (the gauges are up whenever the field is)
        g.call("hud", action="show", kind=kind, hold=True, **SHOW[kind])
    s0 = stats()
    drawn = g.until(lambda: (lambda s: s["drawn"] >= s0["drawn"] + 2 and s["claimed_by"] == "rood.classic"
                             and s["honoured"])(stats()), guard=60)
    s = stats()
    check(bool(drawn) and s["suppressed"] > s0["suppressed"],
          f"{kind}: drawn by rood.classic by default (honoured, suppressed {s['suppressed'] - s0['suppressed']}, "
          f"drawn {s['drawn'] - s0['drawn']})")

    def game_draws(why):
        s1 = stats()
        ok = g.until(lambda: (lambda s: s["fallback"] >= s1["fallback"] + 2 and not s["honoured"])(stats()), guard=60)
        s2 = stats()
        check(bool(ok) and s2["drawn"] == s1["drawn"],
              f"{kind}, {why}: the game draws it (fallback {s2['fallback'] - s1['fallback']}, Lua draws "
              f"{s2['drawn'] - s1['drawn']})")

    def lua_draws(why):
        s1 = stats()
        ok = g.until(lambda: (lambda s: s["drawn"] >= s1["drawn"] + 2 and s["honoured"])(stats()), guard=60)
        check(bool(ok), f"{kind}, {why}: rood.classic draws it again")

    g.call("settings", apply=f"hud_classic_{kind} 0")
    game_draws(f"hud_classic_{kind} 0")
    g.call("settings", apply=f"hud_classic_{kind} 1")
    lua_draws(f"hud_classic_{kind} 1")
    repl(g, "rood.classic", f"M.draw.{kind} = function() error('a broken classic draw') end return true")
    faults = stats()["faults"]
    game_draws("a draw that raises")
    check(stats()["faults"] > faults and stats()["claim_failed"], f"{kind}: the fault counted, the claim failed")
    g.call("lua", action="reload", plugin="rood.classic")
    lua_draws("the plugin reloaded")
    g.call("lua", action="enable", plugin="rood.classic", enabled=False)
    game_draws("rood.classic off")
    g.call("lua", action="enable", plugin="rood.classic", enabled=True)
    lua_draws("rood.classic on")
    g.call("hud", action="clear")


POPUPS = ("buff", "damage", "actor_word", "timer", "text_band")


def packet_masks(symbols, pointer):
    """More of what the proof leaves out as packets, beside the primitive buffers and the ordering table: the
    text boxes' private ordering tables (D_800F4CD0: three of 34 links, spliced into the frame's) and the room
    drawing's copies of the packet pointer (D_800F1CC0, D_800F1BB8, 146C.c). A classic draw allocates its
    packets after the game's no-ops, so later packets, and the links to them, sit further on."""
    masks = [[symbols["D_800F4CD0"], 3 * 34 * 4]]
    rows = {name: a for a, n, name in Symbols(rood_rpc.BINARY).rows if name in ("D_800F1CC0", "D_800F1BB8")}
    return masks + [[a, pointer] for a in rows.values()]


def state_masks(g):
    """What a state proof leaves out: the packet pointer, the frame's primitive buffers and ordering tables, the host
    clock, packet_masks'."""
    symbols = rood_rpc.symbols()
    pointer = 8 if pathlib.Path(rood_rpc.BINARY).read_bytes()[4] == 2 else 4  # (ELF class: the arrays' pointers)
    masks = [[0x1F800000, 4]]  # vs_scratch.unk0, the packet pointer
    for name, size in (("D_8005E0C0", 0x20000), ("D_80055C80", 0x822 * 4)):  # the frame's two of each
        for i in range(2):
            address = int.from_bytes(g.read(symbols[name] + pointer * i, pointer), "little")
            masks.append([address, size])
    masks += [[a, n] for a, n, name in Symbols(rood_rpc.BINARY).rows if name == "last_vsync" and n == 2 * pointer]
    return masks + packet_masks(symbols, pointer)


TARGETING = ("target_row", "target_line")  # (the kinds whose state proof runs with targeting up)


def target_state_parity(g, check, ticks=120):
    """§3.4 for targeting: from one mark in targeting, rows coming in from both sides (their plates fading) and a
    selected one with its leader lines, drawn by rood.classic, then by the game: every vsync's state the same but for the packets."""
    masks = state_masks(g)
    if not check(targeting(g), "targeting state parity: targeting up"):
        return
    names = limb_names(g)
    clear_rows(g)
    write_row(g, 0, state=2, x=320, y=32, text=names[1][0])
    write_row(g, 1, state=3, x=-72, y=43, bank=1, text=names[2][0])
    write_row(g, 2, selected=1, age=20, y=54, text=names[3][0])  # (its leader lines, both)
    g.run(2)
    g.pause()
    g.mark()
    g.rewind()
    stats = lambda: g.call("hud", action="stats")["kinds"]  # noqa: E731
    drawn = {k: stats()[k]["drawn"] for k in TARGETING}
    g.call("input", buttons=[], vsyncs=ticks + 20)
    g.digest("record", ticks=ticks, masks=masks)
    g.until(lambda: g.digest("result")["recorded"] >= ticks, guard=120, what="the digest recorded")
    drawn = {k: stats()[k]["drawn"] - n for k, n in drawn.items()}
    g.rewind()
    g.call("settings", apply=[f"hud_classic_{k} 0" for k in TARGETING])
    fallback = {k: stats()[k]["fallback"] for k in TARGETING}
    g.call("input", buttons=[], vsyncs=ticks + 20)
    g.digest("compare")
    g.until(lambda: g.digest("result")["ticks"] >= ticks, guard=120, what="the digest compared")
    result = g.digest("result")
    fallback = {k: stats()[k]["fallback"] - n for k, n in fallback.items()}
    g.call("settings", apply=[f"hud_classic_{k} 1" for k in TARGETING])
    for k in TARGETING:
        check(drawn[k] > 0 and fallback[k] > 0, f"targeting state parity {k}: Lua drew {drawn[k]}, game drew "
                                                f"{fallback[k]}")
    check(result.get("error") == 0 and result.get("first_tick") == -1 and result.get("ticks") == result.get("recorded"),
          f"targeting state parity: {result.get('ticks')} of {result.get('recorded')} vsyncs the same (first difference "
          f"{result.get('first_tick')} {result.get('first_pages')})")
    clear_rows(g)


def state_parity(g, check, ticks=120, ability_hold=True):
    """§3.4: SLOW! held (and the gauges up), from one mark: rood.classic drawing them, then the game; every
    vsync's state
    (guest memory, the native game state, VRAM) the same but for the packets (the primitive buffers,
    the ordering tables, the packet pointer) and the host clock (last_vsync, as snapshot_diff and the
    oracle's own proof mask it). Both runs start from a rewind (the mark's)."""
    masks = state_masks(g)
    g.call("hud", action="show", kind="status", hold=True, timing="slow", age=10)
    for kind in ("buff", "damage"):  # (held beside it: both drawn by rood.classic, then by the game)
        g.call("hud", action="show", kind=kind, hold=True, **SHOW[kind])
    spawn_word(g, index=6, flags=1)  # (a lowered stat's word playing out from the mark: in both runs)
    g.call("hud", action="show", kind="name_window", hold=True)  # (its band, held)
    start = g.call("hud", action="stats")["kinds"]["status"]["drawn"]
    g.until(lambda: g.call("hud", action="stats")["kinds"]["status"]["drawn"] >= start + 2, guard=60,
            what="SLOW! drawn by rood.classic")
    g.pause()
    g.mark()
    g.rewind()
    g.call("input", buttons=["l2", "r2"] if ability_hold else [], vsyncs=ticks + 20)
    g.digest("record", ticks=ticks, masks=masks)
    lua_drawn = g.call("hud", action="stats")["kinds"]["status"]["drawn"]
    figure_drawn = g.call("hud", action="stats")["kinds"]["figure"]["drawn"]
    icons_drawn = g.call("hud", action="stats")["kinds"]["status_icons"]["drawn"]
    battle_drawn = g.call("hud", action="stats")["kinds"]["battle_mode"]["drawn"]
    ability_drawn = g.call("hud", action="stats")["kinds"]["ability_icons"]["drawn"]
    popups_drawn = {k: g.call("hud", action="stats")["kinds"][k]["drawn"] for k in POPUPS}
    g.until(lambda: g.digest("result")["recorded"] >= ticks, guard=120, what="the digest recorded")
    lua_drawn = g.call("hud", action="stats")["kinds"]["status"]["drawn"] - lua_drawn
    figure_drawn = g.call("hud", action="stats")["kinds"]["figure"]["drawn"] - figure_drawn
    icons_drawn = g.call("hud", action="stats")["kinds"]["status_icons"]["drawn"] - icons_drawn
    battle_drawn = g.call("hud", action="stats")["kinds"]["battle_mode"]["drawn"] - battle_drawn
    ability_drawn = g.call("hud", action="stats")["kinds"]["ability_icons"]["drawn"] - ability_drawn
    popups_drawn = {k: g.call("hud", action="stats")["kinds"][k]["drawn"] - n for k, n in popups_drawn.items()}
    g.rewind()
    g.call("settings", apply=["hud_classic_status 0", "hud_classic_chain 0", "hud_classic_gauges 0", "hud_classic_figure 0", "hud_classic_status_icons 0", "hud_classic_battle_mode 0", "hud_classic_ability_icons 0", "hud_classic_buff 0", "hud_classic_damage 0", "hud_classic_actor_word 0", "hud_classic_timer 0", "hud_classic_text_band 0"])
    fallback = g.call("hud", action="stats")["kinds"]["status"]["fallback"]
    figure_fallback = g.call("hud", action="stats")["kinds"]["figure"]["fallback"]
    icons_fallback = g.call("hud", action="stats")["kinds"]["status_icons"]["fallback"]
    battle_fallback = g.call("hud", action="stats")["kinds"]["battle_mode"]["fallback"]
    ability_fallback = g.call("hud", action="stats")["kinds"]["ability_icons"]["fallback"]
    popups_fallback = {k: g.call("hud", action="stats")["kinds"][k]["fallback"] for k in POPUPS}
    g.call("input", buttons=["l2", "r2"] if ability_hold else [], vsyncs=ticks + 20)
    g.digest("compare")
    g.until(lambda: g.digest("result")["ticks"] >= ticks, guard=120, what="the digest compared")
    result = g.digest("result")
    fallback = g.call("hud", action="stats")["kinds"]["status"]["fallback"] - fallback
    figure_fallback = g.call("hud", action="stats")["kinds"]["figure"]["fallback"] - figure_fallback
    icons_fallback = g.call("hud", action="stats")["kinds"]["status_icons"]["fallback"] - icons_fallback
    battle_fallback = g.call("hud", action="stats")["kinds"]["battle_mode"]["fallback"] - battle_fallback
    ability_fallback = g.call("hud", action="stats")["kinds"]["ability_icons"]["fallback"] - ability_fallback
    popups_fallback = {k: g.call("hud", action="stats")["kinds"][k]["fallback"] - n for k, n in popups_fallback.items()}
    for kind in POPUPS:
        check(popups_drawn[kind] > 0 and popups_fallback[kind] > 0,
              f"state parity {kind}: Lua drew {popups_drawn[kind]} frames, game drew {popups_fallback[kind]}")
    check(ability_drawn == ability_fallback and ability_drawn >= (ticks * 9 // 4 if ability_hold else 9),
          f"state parity ability_icons: Lua drew {ability_drawn} groups, game drew {ability_fallback}")
    check(battle_drawn > 0 and battle_fallback > 0,
          f"state parity battle_mode: Lua drew {battle_drawn} frames, game drew {battle_fallback}")
    check(icons_drawn > 0 and icons_fallback > 0,
          f"state parity status_icons: Lua drew {icons_drawn} frames, game drew {icons_fallback}")
    check(figure_drawn > 0 and figure_fallback > 0,
          f"state parity figure: Lua drew {figure_drawn} frames, game drew {figure_fallback}")
    g.call("settings", apply=["hud_classic_status 1", "hud_classic_chain 1", "hud_classic_gauges 1", "hud_classic_figure 1", "hud_classic_status_icons 1", "hud_classic_battle_mode 1", "hud_classic_ability_icons 1", "hud_classic_buff 1", "hud_classic_damage 1", "hud_classic_actor_word 1", "hud_classic_timer 1", "hud_classic_text_band 1"])
    g.call("hud", action="clear")
    check(lua_drawn > 0 and fallback > 0 and result.get("error") == 0 and result.get("first_tick") == -1
          and result.get("ticks") == result.get("recorded"),
          f"state parity: {result.get('ticks')} of {result.get('recorded')} vsyncs the same (rood.classic drew "
          f"{lua_drawn} frames, the game {fallback}; first difference {result.get('first_tick')} "
          f"{result.get('first_pages')})")


if __name__ == "__main__":
    sys.exit(main())
