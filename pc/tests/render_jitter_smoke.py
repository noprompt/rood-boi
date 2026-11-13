#!/usr/bin/env python3
"""The R4 gate (T1): the renderer side's timing must not show in the game.

    python3 pc/tests/render_jitter_smoke.py [--routes data,setup,platforms] [--seeds 1,2,3]

Each route is played (build_compare.py --play-menus, with the interpolated frame's target hashed too: BUILD_COMPARE_REPLAY,
present_rate 4) once without noise and once per seed with ROOD_RENDER_JITTER=seed: seeded sleeps at the points where the game
hands work to the renderer side (the present service and the fences: render_jitter.h). Every run must give the same frame hashes (the picture and the interpolated target),
the same end state of the game (snapshot hashes) and the same VRAM stream digest, and the noise must actually have fired
(RPC vram_stream "jitter"). The renderer side is inline today, so it passes today; it stays the gate when the renderer
becomes a thread: a failure there is a timing dependence.
"""
import argparse
import json
import os
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
failures = []


def check(ok, message):
    print(("ok:   " if ok else "FAIL: ") + message)
    if not ok:
        failures.append(message)
    return ok


def play(route, seed, work):
    out = pathlib.Path(tempfile.mkdtemp(prefix=f"jitter-{route}-", dir=work))
    env = dict(os.environ, BUILD_COMPARE_REPLAY="1")
    if seed is None:
        env.pop("ROOD_RENDER_JITTER", None)
    else:
        env["ROOD_RENDER_JITTER"] = f"{seed}:2500:350"
    binary = os.environ.get("ROOD_BINARY") or str(ROOT / "pc/build/boot64/rood_battle_probe")
    cmd = [sys.executable, str(ROOT / "pc/tools/build_compare.py"), binary, "--play-menus", "--menus", route, "--menu-sample", "3",
           "--env", "ROOD_SCALE=1", "--setting", "interpolate 1", "--setting", "present_rate 4", "--out", str(out)]
    done = subprocess.run(cmd, cwd=ROOT, env=env, capture_output=True, text=True, timeout=1800)
    for line in done.stdout.splitlines():
        if line.startswith("RESULT"):
            return json.loads(line[6:])[route]
    print(done.stdout[-600:], done.stderr[-600:])
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--routes", default="data,setup,platforms")
    parser.add_argument("--seeds", default="1,2,3")
    args = parser.parse_args()
    seeds = [int(s) for s in args.seeds.split(",")]
    work = tempfile.mkdtemp(prefix="render-jitter-")
    for route in args.routes.split(","):
        base = play(route, None, work)
        if not check(base is not None and base.get("final"), f"{route}: played without noise"):
            continue
        for seed in seeds:
            run = play(route, seed, work)
            if not check(run is not None and run.get("final"), f"{route}: played with seed {seed}"):
                continue
            jitter = run["final"].get("jitter") or {}
            check(jitter.get("sleeps", 0) > 0, f"{route} seed {seed}: the noise fired ({jitter.get('sleeps')} sleeps)")
            a, b = base["hashes"], run["hashes"]
            bad = [i for i, (x, y) in enumerate(zip(a, b)) if x != y]
            check(len(a) == len(b) and not bad,
                  f"{route} seed {seed}: the {len(a)} frame hashes (picture and interpolated target) equal ({len(bad)} differ{' from ' + str(bad[0]) if bad else ''})")
            mine, theirs = run["final"]["snapshot"], base["final"]["snapshot"]
            differ = [k for k in theirs if mine.get(k) != theirs[k]]
            check(not differ, f"{route} seed {seed}: the game's end state equal (every snapshot hash: RAM, scratchpad, I/O, "
                              f"native statics, overlays, VRAM{'; differ: ' + ', '.join(differ) if differ else ''})")
            check(run["final"]["stream"] == base["final"]["stream"],
                  f"{route} seed {seed}: the VRAM stream digest equal")
    if failures:
        print(f"{len(failures)} check(s) failed")
        return 1
    print("PASS: render_jitter_smoke")
    return 0


if __name__ == "__main__":
    sys.exit(main())
