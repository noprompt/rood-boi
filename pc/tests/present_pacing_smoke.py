#!/usr/bin/env python3
"""Display pacing's phases (T1 R5): with a simulated display refresh (ROOD_PRESENT_SIM_HZ=hz[:variation]: a fake vblank clock, no
waiting; the variation, a fraction, makes each interval longer or shorter at random as a variable refresh rate display does),
present_pacing display must give every image of a game field the phase its vblank puts it at: strictly later than the image
before, evenly spaced on the game's clock (the spacing is the refresh interval), and a number of images per field that follows
the refresh over the field rate (90 Hz: 1, 2, 1, 2; 144 Hz: 2, 3, 2, 3, 2). The numbers are read back from RPC present_stats
(order_violations, image_spacing_ms, images_per_field, recent), the same ones a run on a real display reports.

    python3 pc/tests/present_pacing_smoke.py
"""
import os
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "tools"))
from rood_rpc import OUT, Game  # noqa: E402

FIELD_HZ = 59.94
failures = []


def check(ok, message):
    print(("ok:   " if ok else "FAIL: ") + message)
    if not ok:
        failures.append(message)
    return ok


def run_case(label, sim, hz, variation):
    game = Game.launch(socket_path=f"/tmp/rood-pace-{os.getpid()}-{label}.sock", log=str(OUT / f"present-pacing-{label}.log"),
                       extra_env={"ROOD_PRESENT_SIM_HZ": sim, "ROOD_SETTINGS": str(OUT / f"present-pacing-{label}.cfg")}, fast=True)
    try:
        game.wait_title()
        game.call("graphics", interpolate=True, present_rate=0, present_pacing=1)
        game.run(30)
        game.call("present_stats", reset=True)
        game.run(360)
        st = game.call("present_stats")
    finally:
        game.close()
    interval = 1000.0 / hz
    spacing, per_field = st["image_spacing_ms"], st["images_per_field"]
    check(st["sim_hz"] == hz and st["pacing"] == 1, f"{label}: the simulated display at {hz} Hz drives display pacing")
    check(st["order_violations"] == 0, f"{label}: every image later than the one before ({st['order_violations']} violations)")
    check(abs(per_field["mean"] - hz / FIELD_HZ) < 0.05,
          f"{label}: {per_field['mean']:.3f} images a field (the refresh over the field rate: {hz / FIELD_HZ:.3f}); counts {per_field['counts']}")
    low, high = int(hz // FIELD_HZ), int(hz // FIELD_HZ) + 1
    used = [k + 1 for k, c in enumerate(per_field["counts"]) if c]
    check(set(used) <= {low, high} and (low == high or len(used) == 2 or hz == low * FIELD_HZ),
          f"{label}: fields hold {used} images (a whole number below and above the ratio)")
    tolerance = interval * (variation + 0.02)
    check(abs(spacing["mean"] - interval) < max(0.05, interval * 0.02),
          f"{label}: images {spacing['mean']:.3f} ms apart on the game's clock (the refresh interval {interval:.3f})")
    check(spacing["min"] > interval - tolerance and spacing["max"] < interval + tolerance,
          f"{label}: spacing within {tolerance:.3f} ms of the interval (min {spacing['min']:.3f}, max {spacing['max']:.3f})")
    check(variation or spacing["stddev"] < 0.02, f"{label}: even spacing (deviation {spacing['stddev']:.4f} ms)")
    phases = st["recent"]
    ok = all(0.0 <= p < 1.0 for _, p in phases) and all(
        (b[0] - a[0]) + (b[1] - a[1]) > 0 for a, b in zip(phases, phases[1:]))
    check(ok and len(phases) >= 24, f"{label}: the last {len(phases)} (field, phase) pairs rise and stay inside the field")


def main():
    run_case("90hz", "90", 90.0, 0.0)
    run_case("144hz", "144", 144.0, 0.0)
    run_case("vrr", "90:0.2", 90.0, 0.2)
    if failures:
        print(f"{len(failures)} check(s) failed")
        return 1
    print("PASS: present_pacing_smoke")
    return 0


if __name__ == "__main__":
    sys.exit(main())
