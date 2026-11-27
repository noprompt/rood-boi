#!/usr/bin/env python3
"""The fixed cost of a frame stays off the game thread (pc/src/frame_cost.h,
ROOD_PERF=1 counters through RPC perf), and what it no longer does draws
the same pictures.

    python3 pc/tests/frame_cost_smoke.py [--card CARD] [--out DIR]

From a copy of the card inside card_fixtures.card_guard (skipped without
one), in the save room, unpaced:
  - standing (120 vsyncs): no read-back of the target; the emissive
    matching hashes almost nothing (unmatched textures are hashed again
    only when their VRAM changed, not every frame); loading.ppm is not
    rewritten every frame;
  - battle mode, the targeting sphere held: rows of the picture it samples
    are captures of the target (no copy, no read-back) (each read-back
    waited for the GPU's whole frame: the sphere and the menus dropped to
    12-20 fps with path tracing on);
  - the original Status screen (it redraws rows of its own picture): no
    read-back either."""
import argparse
import os
import pathlib
import sys


ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
sys.path.insert(0, str(ROOT / "pc/tests"))
from rood_rpc import OUT  # noqa: E402
from checkpoints import launch_at  # noqa: E402
from card_fixtures import card_guard, default_save  # noqa: E402

failures = []


def check(ok, what):
    print(("ok:   " if ok else "FAIL: ") + what, flush=True)
    if not ok:
        failures.append(what)
    return ok


def measure(game, vsyncs):
    game.call("perf", reset=True)
    game.run(vsyncs)
    perf = game.call("perf", reset=True)
    return perf.get("cpu_counts"), perf.get("cpu_sections", {})


def play(card, out, name, extra):
    """The three moments in one game: their counters."""
    env = {"ROOD_PERF": "1", "ROOD_GI": "0", "ROOD_LIGHTS": str(out / f"lights-{name}"), "ROOD_WINDOW": "960x720",
           **extra}
    game = launch_at("save_room", card=str(card), fast=True, log=out / f"{name}.log", extra_env=env)
    result = {}
    try:
        game.run(30)
        game.call("graphics", interpolate=False)  # (a replay of an interpolated frame keeps its copies: the live frame's are counted)
        result["field"] = measure(game, 120)
        game.press("circle", vsyncs=3, settle=60)  # the weapon drawn
        game.call("input", buttons=["circle"], vsyncs=3)
        game.run(40)  # the targeting sphere open
        result["sphere"] = measure(game, 60)
        for _ in range(3):
            game.press("cross", vsyncs=3, settle=40)
        game.run(60)
        for button, settle in (("triangle", 90), ("down", 20), ("down", 20), ("circle", 150)):
            game.press(button, vsyncs=4, settle=settle)
        result["status"] = measure(game, 60)
    finally:
        game.close()
    return result


def run(args, out, card):
    new = play(card, out, "new", {})
    counts, sections = new["field"]
    if not check(counts is not None, "RPC perf reports the game thread's counters (cpu_counts)"):
        return 1
    print(f"      field: {sections.get('vsync', 0):.3f} ms a vsync; {counts}")
    check(counts["readbacks"] == 0, f"standing: no read-back ({counts['readbacks']} a vsync)")
    check(counts["hashed_texels"] < 2000,
          f"standing: emissive matching hashes {counts['hashed_texels']:.0f} texels a vsync (< 2000)")
    check(counts["debug_ppm"] < 0.1, f"standing: loading.ppm written {counts['debug_ppm']:.2f} times a vsync")
    for scene in ("sphere", "status"):
        counts, sections = new[scene]
        print(f"      {scene}: {sections.get('vsync', 0):.3f} ms a vsync; {counts}")
        check(counts["readbacks"] == 0 and counts["gpu_copies"] == 0,
              f"{scene}: the rows of its own picture it samples are captures, not copies ({counts['gpu_copies']:.1f} copies a vsync), "
              f"no read-back ({counts['readbacks']:.1f})")
    return 1 if failures else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--card", default=str(default_save()))
    parser.add_argument("--out", help="where the game's logs and lights go")
    args = parser.parse_args()
    if not pathlib.Path(args.card).exists():
        print("SKIP: no memory card", args.card)
        return 77
    out = pathlib.Path(args.out) if args.out else OUT / "frame_cost"
    out.mkdir(parents=True, exist_ok=True)
    os.environ.pop("ROOD_SETTINGS", None)  # the defaults, not the user's settings
    with card_guard(out / "cards", source=args.card) as cards:
        status = run(args, out, cards.card1)
    print("PASS" if not status else f"FAIL ({len(failures)})")
    return status


if __name__ == "__main__":
    sys.exit(main())
