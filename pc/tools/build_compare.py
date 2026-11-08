#!/usr/bin/env python3
"""Does a change alter the game? The same fight on two builds, frame by frame.

    python3 pc/tools/build_compare.py OLD_BINARY [NEW_BINARY] [--card CARD] [--seconds 30]

Afterwards every enemy is defeated (its HP written to 0) and the loot the game builds
is compared too: how many drop nodes, each one's actor id and item bytes.

Runs are deterministic (no wall clock in game logic, no input), so two builds of
the same behaviour draw the same frames. A room with enemies is entered from the
save room checkpoint and left to play: the enemies walk, attack and cast. Every
quarter second the frame's hash is taken and, at the end, what was cast. NEW_BINARY
defaults to this tree's build. OLD against OLD runs first as the control: if that
differs, the comparison proves nothing and the tool says so. Exit 0 when the frames
match. Covers this fight only, not every screen or effect.

    python3 pc/tools/build_compare.py OLD_BINARY --casts [spells,arts] [--cast-limit N]

The wider lane: instead of the fight, Ashley casts every spell of the four schools (and
the equipped category's Break Arts) through the menus, as tests/charge_skip_soak.py does,
and the display is hashed every few vsyncs through each action. Old, old again (the
control) and new are compared action by action. Where the new build records them
(RPC effect_sites), the effect polygon call sites that ran are mapped to plugin
functions and counted against all of the build's (the coverage the frames cover).
Slow (several minutes); its actions are the spells' effect plugins, not every one.
"""
import argparse
import hashlib
import json
import os
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
ROOM = (48, 10)


ROOM_ENEMIES = range(2, 10)  # vs_battle_actors slots of the room's enemies
ACTOR_STATS, STATS_HP = 0x3C, 0x18  # vs_battle_actor.unk3C (a 4-byte guest pointer), vs_battle_actor2.currentHP
LOOT_BYTES = 0x220  # vs_battle_loot; a drop node is: next (the pointer's width), int actorId, the loot


def loot(g, width):
    """Defeat the room's enemies and read the drop list: [(actor id, item bytes hash)]."""
    from rood_rpc import symbols
    sym = symbols()
    pointers = g.read(sym["vs_battle_actors"], 16 * 8)
    for slot in ROOM_ENEMIES:
        actor = int.from_bytes(pointers[slot * 8:slot * 8 + 8], "little")
        stats = int.from_bytes(g.read(actor + ACTOR_STATS, 4), "little") if actor else 0
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
    out = pathlib.Path(out)
    (out / "settings.cfg").write_text("qol_skip_charging 0\nui_menus 0\n")
    g = start(card, out, "fight")
    try:
        g.call("skip_charging", reset=True)
        frames = []
        for _ in range(seconds * 4):
            g.run(15)
            shot = out / "frame.ppm"
            g.screenshot(str(shot))
            frames.append(hashlib.sha256(shot.read_bytes()).hexdigest()[:16])
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
    print("RESULT" + json.dumps({"frames": frames, "casts": casts, "drops": drops}))


SCHOOLS = (("warlock", 18), ("shaman", 6), ("sorcerer", 18), ("enchanter", 8))
SAMPLE = 6  # vsyncs between display hashes in an action


def play_casts(binary, card, out, kinds, limit):
    """Every spell (and art) cast with its holds skipped, the display hashed through each: {action: [hashes]}, and
    the effect polygon call sites the build recorded (empty for a build without the RPC)."""
    os.environ.update(ROOD_BINARY=binary, ROOD_SYMBOLS=binary, ROOD_HEADLESS="egl", ROOD_RENDERER="vulkan", ROOD_ARCH="64",
                      ROOD_TEST_SNAPSHOTS="0")
    sys.path[:0] = [str(ROOT / "pc/tools"), str(ROOT / "pc/tests")]
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
            for i in range(soak.WATCHDOG // SAMPLE):
                g.run(SAMPLE)
                shot = out / "frame.ppm"
                g.screenshot(str(shot))
                hashes.append(hashlib.sha256(shot.read_bytes()).hexdigest()[:12])
                if i > 2 and self.mode_now()[0] == 1:
                    break
            g.run(4)
            return hashes

    r = Cast("casts", snap, card_copy, env, out, socket, fast=True)
    g, sym = r.g, r.sym
    actions, sites, peak = {}, [], 0
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
        try:
            reply = g.call("effect_sites")
            sites, peak = reply["sites"], reply["peak_items"]
        except Exception:
            sites, peak = [], 0
    finally:
        r.close()
    print("RESULT" + json.dumps({"actions": actions, "sites": sites, "peak": peak}))


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
    with tempfile.TemporaryDirectory(prefix="build-compare-", dir=ROOT / "pc/build") as out:
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
    parser.add_argument("--out", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.play:
        return play(args.old, args.seconds, args.card, args.out, args.width)
    if args.play_casts:
        return play_casts(args.old, args.card, args.out, args.casts, args.cast_limit)
    if args.casts:
        return compare_casts(args)
    first, control, new = run(args.old, args, args.old_width), run(args.old, args, args.old_width), run(args.new, args, args.new_width)
    noise, changed = differing(first, control), differing(first, new)
    print(f"control (old against old): {len(noise)} of {len(first['frames'])} frames differ")
    print(f"old against new: {len(changed)} of {len(first['frames'])} frames differ{f' (first at {changed[0] / 4:.2f} s)' if changed else ''}")
    print(f"casts: old {len(first['casts'])}, new {len(new['casts'])}; the same: {first['casts'] == new['casts']}")
    print(f"drops: old {len(first['drops'])}, new {len(new['drops'])}; the same: {first['drops'] == new['drops']}")
    if noise:
        print("build_compare: the control differs, so this proves nothing")
        return 2
    if not first["casts"]:
        print("build_compare: no enemy cast in this run: extend --seconds")
        return 2
    if not first["drops"]:
        print("build_compare: no enemy dropped anything")
        return 2
    return 0 if not changed and first["casts"] == new["casts"] and first["drops"] == new["drops"] else 1


if __name__ == "__main__":
    sys.exit(main())
