#!/usr/bin/env python3
"""Does a change alter the game? The same fight on two builds, frame by frame.

    python3 pc/tools/build_compare.py OLD_BINARY [NEW_BINARY] [--card CARD] [--seconds 30]

Runs are deterministic (no wall clock in game logic, no input), so two builds of
the same behaviour draw the same frames. A room with enemies is entered from the
save room checkpoint and left to play: the enemies walk, attack and cast. Every
quarter second the frame's hash is taken and, at the end, what was cast. NEW_BINARY
defaults to this tree's build. OLD against OLD runs first as the control: if that
differs, the comparison proves nothing and the tool says so. Exit 0 when the frames
match. Covers this fight only, not every screen or effect.
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


def play(binary, seconds, card, out):
    """In a process of its own (ROOD_BINARY is read at import): the hashes and the casts, as JSON on stdout."""
    os.environ.update(ROOD_BINARY=binary, ROOD_HEADLESS="egl", ROOD_RENDERER="vulkan", ROOD_ARCH="64", ROOD_TEST_SNAPSHOTS="0")
    sys.path[:0] = [str(ROOT / "pc/tools"), str(ROOT / "pc/tests")]
    from checkpoints import launch_at
    out = pathlib.Path(out)
    (out / "settings.cfg").write_text("qol_skip_charging 0\nui_menus 0\n")
    g = launch_at("save_room", card=card, fast=True, log=out / "game.log", extra_env={
        "ROOD_GI": "0", "ROOD_INTERPOLATE": "0", "ROOD_SETTINGS": str(out / "settings.cfg"), "ROOD_AUDIO": "none",
        "ROOD_WINDOW": "960x720", "ROOD_LIGHTS": str(out / "lights"), "ROOD_PREFABS": str(out / "prefabs")})
    try:
        g.call("graphics", interpolate=False)
        g.call("room_goto", zone=ROOM[0], room=ROOM[1], enemies=True, scripts=False)
        for _ in range(80):
            g.run(20)
            if g.call("room_goto", action="status")["phase"] in (0, 4):
                break
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
    casts = [e for e in (entry.split(":") for entry in ended.split()) if len(e) >= 4 and int(e[0]) != 0 and e[2] == "1"]
    print("RESULT" + json.dumps({"frames": frames, "casts": casts}))


def run(binary, args):
    with tempfile.TemporaryDirectory(prefix="build-compare-", dir=ROOT / "pc/build") as out:
        done = subprocess.run([sys.executable, __file__, "--play", binary, "--seconds", str(args.seconds), "--card", args.card,
                               "--out", out], capture_output=True, text=True)
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
    parser.add_argument("--play", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--out", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.play:
        return play(args.old, args.seconds, args.card, args.out)
    first, control, new = run(args.old, args), run(args.old, args), run(args.new, args)
    noise, changed = differing(first, control), differing(first, new)
    print(f"control (old against old): {len(noise)} of {len(first['frames'])} frames differ")
    print(f"old against new: {len(changed)} of {len(first['frames'])} frames differ{f' (first at {changed[0] / 4:.2f} s)' if changed else ''}")
    print(f"casts: old {len(first['casts'])}, new {len(new['casts'])}; the same: {first['casts'] == new['casts']}")
    if noise:
        print("build_compare: the control differs, so this proves nothing")
        return 2
    if not first["casts"]:
        print("build_compare: no enemy cast in this run: extend --seconds")
        return 2
    return 0 if not changed and first["casts"] == new["casts"] else 1


if __name__ == "__main__":
    sys.exit(main())
