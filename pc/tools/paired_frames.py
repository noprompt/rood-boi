#!/usr/bin/env python3
"""Paired frames and the brightness table: how a picture change looks, and by how much it moved the brightness.

    python3 pc/tools/paired_frames.py --record               the current build's table -> pc/tests/look_reference.json (numbers only)
    python3 pc/tools/paired_frames.py --check                the current build against that table: drift above 3% is flagged (exit 1)
    python3 pc/tools/paired_frames.py OLD [--out DIR]        OLD and the current build at the same views: a sheet per view
                                                             (old | new | difference x4) and the table with both
    python3 pc/tools/paired_frames.py --just [--out DIR]     only the current build: its pictures under DIR/new and the tables

Environment: PAIRED_GI=1 (the path-traced GI at Ultra), PAIRED_ONLY="view;view" (the views to take), PAIRED_SETTINGS="key=value;key=value"
(graphics RPC settings, lighting keys among them, applied to the new build only; PAIRED_OLD_SETTINGS to the old one). Every table also
has the blotch measure of noise_band.py (the speckle of the lighting over flat walls and floors).

The views (VIEWS) are states the game reaches the same way in every build: the title, the opening's first bubble, the save room, and
the fight in three rooms at two moments. Each is the picture the window shows (RPC present_dump) with the settings that give the
original's look (no GI, no interpolation, the shipped plugins on). The table is the mean luminance (Rec. 709 weights on the display's
encoded values, 0 to 255) and the mean of each channel, for the whole frame and for its top third, middle and bottom third: a change
of exposure, tone or tint shows as a ratio away from 1. Presentation changes (a new look default, a converted asset, a screen quad)
go to the user on the sheets with these numbers; the original's values are the default (a port once drifted to a third of the
original's brightness unnoticed), so a ratio beyond DRIFT is a finding, not a note.

The sheets hold game pictures: they stay under pc/build (never committed). The reference file holds numbers only.
"""
import argparse
import json
import os
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "pc/tests/look_reference.json"
DRIFT = 0.03
# (name, checkpoint, room or None, vsyncs after the checkpoint (or the room's fight start) the picture is taken at)
VIEWS = [
    ("title", "title", None, 0),
    ("first bubble", "first_bubble", None, 0),
    ("save room", "save_room", None, 60),
    ("fight 48,10 early", "save_room", (48, 10), 180),
    ("fight 48,10 later", "save_room", (48, 10), 540),
    ("fight 40,3 early", "save_room", (40, 3), 180),
    ("fight 40,3 later", "save_room", (40, 3), 540),
    ("fight 10,1 early", "save_room", (10, 1), 180),
    ("fight 10,1 later", "save_room", (10, 1), 540),
    ("materials 28,0", "save_room", (28, 0), 120),  # a room with material responses (reflections: the traced specular)
]
REGIONS = ("whole", "top", "middle", "bottom")


def stats(path):
    """{region: {"lum", "r", "g", "b"}} of a PPM."""
    import numpy as np
    from PIL import Image
    image = np.asarray(Image.open(path).convert("RGB"), dtype=np.float64)
    h = image.shape[0]
    parts = {"whole": image, "top": image[: h // 3], "middle": image[h // 3: 2 * h // 3], "bottom": image[2 * h // 3:]}
    out = {}
    for name, part in parts.items():
        r, g, b = (float(part[..., i].mean()) for i in range(3))
        out[name] = {"lum": round(0.2126 * r + 0.7152 * g + 0.0722 * b, 2), "r": round(r, 2), "g": round(g, 2), "b": round(b, 2)}
    return out


def noise_table(directory):
    """{view: blotch measure} of the pictures kept in `directory`."""
    sys.path.insert(0, str(ROOT / "pc/tools"))
    from noise_band import band_noise
    table = {}
    for index, (view, *_) in enumerate(VIEWS):
        picture = pathlib.Path(directory) / f"{index}.ppm"
        if picture.exists():
            table[view] = band_noise(picture)[0]
    return table


def play(binary, card, out):
    """In a process of its own (ROOD_BINARY is read at import): each view's picture under `out` and the table as JSON on stdout."""
    os.environ.update(ROOD_BINARY=binary, ROOD_SYMBOLS=binary, ROOD_ARCH="64", ROOD_HEADLESS="egl", ROOD_RENDERER="vulkan", ROOD_TEST_SNAPSHOTS="0")
    sys.path[:0] = [str(ROOT / "pc/tools"), str(ROOT / "pc/tests")]
    from checkpoints import launch_at
    out = pathlib.Path(out)
    (out / "settings.cfg").write_text("qol_skip_charging 0\nui_menus 0\nshader_reload 0\ninterpolate 0\n")
    table = {}
    gi = os.environ.get("PAIRED_GI") == "1"  # with the path-traced GI at Ultra (the lighting the user sees), not the original's look
    only = [v for v in os.environ.get("PAIRED_ONLY", "").split(";") if v]
    for index, (name, checkpoint, room, vsyncs) in enumerate(VIEWS):
        if only and name not in only:
            continue
        copy = out / f"card-{index}.mcd"
        copy.write_bytes(pathlib.Path(card).read_bytes())
        g = launch_at(checkpoint, card=str(copy), fast=True, log=out / f"{index}.log", extra_env={
            "ROOD_GI": "1" if gi else "0", **({"ROOD_LIGHTING_PRESET": "ultra"} if gi else {}), "ROOD_INTERPOLATE": "0", "ROOD_SETTINGS": str(out / "settings.cfg"), "ROOD_AUDIO": "none",
            "ROOD_WINDOW": "960x720", "ROOD_OUT": str(out)})
        try:
            settings = os.environ.get("PAIRED_SETTINGS_NOW", "")
            if settings:
                values = {}
                for item in settings.split(";"):
                    key, _, value = item.partition("=")
                    values[key] = float(value) if value.replace(".", "", 1).lstrip("-").isdigit() else value
                g.call("graphics", **values)
            if room:
                g.call("room_goto", hold=True, zone=room[0], room=room[1], enemies=True, scripts=False)
                for _ in range(80):
                    g.run(20)
                    if g.call("room_goto", action="status")["phase"] in (0, 4):
                        break
            if vsyncs:
                g.run(vsyncs)
            ppm = out / f"{index}.ppm"
            ppm.unlink(missing_ok=True)
            g.wait_presents(3)
            g.call("present_dump", path=str(ppm.resolve()))
            for _ in range(200):
                if ppm.exists():
                    break
                g.wait_presents(1)
            table[name] = stats(ppm)
        finally:
            g.close()
    print("RESULT" + json.dumps(table))


def run(binary, card, keep=None, settings=""):
    """The table of `binary`'s views; the pictures go to `keep` (a directory) when given."""
    with tempfile.TemporaryDirectory(prefix="paired-frames-", dir=ROOT / "pc/build") as out:
        done = subprocess.run([sys.executable, __file__, "--play", binary, "--card", card, "--out", out], capture_output=True, text=True,
                              env={**os.environ, "PAIRED_SETTINGS_NOW": settings})
        lines = [line for line in done.stdout.splitlines() if line.startswith("RESULT")]
        if not lines:
            sys.exit(f"paired_frames: {binary} did not finish (exit {done.returncode}):\n{done.stderr[-1500:]}\n{done.stdout[-800:]}")
        if keep:
            pathlib.Path(keep).mkdir(parents=True, exist_ok=True)
            for index, view in enumerate(VIEWS):
                src = pathlib.Path(out) / f"{index}.ppm"
                if src.exists():
                    (pathlib.Path(keep) / f"{index}.ppm").write_bytes(src.read_bytes())
    return json.loads(lines[-1][6:])


def ratio(new, old):
    return new / old if old else (1.0 if not new else float("inf"))


def report(old, new, label_old, label_new):
    """The table; the number of drifted regions."""
    drifted = 0
    print(f"{'view':<20}{'region':<8}{label_old:>9}{label_new:>9}{'ratio':>8}   r/g/b ratio")
    for view in new:
        if view not in old:
            print(f"{view:<20}(not in {label_old})")
            continue
        for region in REGIONS:
            a, b = old[view][region], new[view][region]
            q = ratio(b["lum"], a["lum"])
            flag = abs(q - 1) > DRIFT
            drifted += flag
            print(f"{view:<20}{region:<8}{a['lum']:>9.2f}{b['lum']:>9.2f}{q:>8.3f}   "
                  f"{ratio(b['r'], a['r']):.3f}/{ratio(b['g'], a['g']):.3f}/{ratio(b['b'], a['b']):.3f}{'   DRIFT' if flag else ''}")
    return drifted


def sheets(old_dir, new_dir, out):
    """A sheet a view: old | new | the difference (x4), side by side."""
    import numpy as np
    from PIL import Image
    out = pathlib.Path(out)
    for index, (view, *_) in enumerate(VIEWS):
        a, b = pathlib.Path(old_dir) / f"{index}.ppm", pathlib.Path(new_dir) / f"{index}.ppm"
        if not (a.exists() and b.exists()):
            continue
        x, y = Image.open(a).convert("RGB"), Image.open(b).convert("RGB")
        if x.size != y.size:
            y = y.resize(x.size)
        diff = np.clip(np.abs(np.asarray(x, dtype=np.int16) - np.asarray(y, dtype=np.int16)) * 4, 0, 255).astype(np.uint8)
        sheet = Image.new("RGB", (x.width * 3 + 8, x.height), (255, 0, 255))
        sheet.paste(x, (0, 0))
        sheet.paste(y, (x.width + 4, 0))
        sheet.paste(Image.fromarray(diff), (2 * x.width + 8, 0))
        sheet.save(out / f"{index}-{view.replace(' ', '_').replace(',', '-')}.png")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("old", nargs="?", help="a reference binary: the pairs against the current build")
    parser.add_argument("--new", default=str(ROOT / "pc/build/boot64/rood_battle_probe"))
    parser.add_argument("--card", default=str(ROOT / "pc/build/test-card1.mcd"))
    parser.add_argument("--just", action="store_true", help="only the current build, its pictures kept under --out/new")
    parser.add_argument("--record", action="store_true", help="write the current build's table to " + str(REFERENCE.relative_to(ROOT)))
    parser.add_argument("--check", action="store_true", help="the current build against the recorded table")
    parser.add_argument("--out", default=str(ROOT / "pc/build/paired-frames"))
    parser.add_argument("--play", metavar="BINARY", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.play:
        return play(args.play, args.card, args.out)
    if args.record:
        table = run(args.new, args.card)
        REFERENCE.write_text(json.dumps(table, indent=1, sort_keys=True) + "\n")
        print(f"recorded {len(table)} views to {REFERENCE.relative_to(ROOT)}")
        return 0
    if args.check:
        if not REFERENCE.exists():
            sys.exit("paired_frames: no recorded table (--record first)")
        drifted = report(json.loads(REFERENCE.read_text()), run(args.new, args.card), "recorded", "now")
        print(f"{drifted} regions drifted by more than {DRIFT:.0%}")
        return 1 if drifted else 0
    if args.just:
        out = pathlib.Path(args.out)
        run(args.new, args.card, out / "new", os.environ.get("PAIRED_SETTINGS", ""))
        for view, value in noise_table(out / "new").items():
            print(f"{view:<20}blotch {value:.3f}")
        return 0
    if args.old:
        out = pathlib.Path(args.out)
        old = run(args.old, args.card, out / "old", os.environ.get("PAIRED_OLD_SETTINGS", ""))
        new = run(args.new, args.card, out / "new", os.environ.get("PAIRED_SETTINGS", ""))
        sheets(out / "old", out / "new", out)
        drifted = report(old, new, "old", "new")
        noise_old, noise_new = noise_table(out / "old"), noise_table(out / "new")
        print(f"\n{'view':<20}{'blotch old':>11}{'blotch new':>11}{'ratio':>8}")
        for view in noise_new:
            if view in noise_old:
                print(f"{view:<20}{noise_old[view]:>11.3f}{noise_new[view]:>11.3f}{ratio(noise_new[view], noise_old[view]):>8.2f}")
        print(f"{drifted} regions drifted by more than {DRIFT:.0%}; sheets in {out}")
        return 1 if drifted else 0
    parser.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
