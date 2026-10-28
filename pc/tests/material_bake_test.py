#!/usr/bin/env python3
"""Disc-free checks of the material bake (pc/tools/material_bake.py,
pc/docs/Materials.md "Baked maps"), on made-up textures and catalogs:

- a block wall (pale blocks with painted shading, dark mortar seams, palette
  noise) bakes height, roughness at exactly its size, 8-bit grayscale; the
  mortar lies below the blocks, the height's mean is near 128, the painted
  shading does not become a slope (the block faces' left and right halves
  agree), the blocks are not speckled (their texels' spread is small), the
  seams are rougher; plain stone gets no metal.png;
- a grey iron plate under a metal preset gets metal where it is grey and
  bright, none on its rust;
- targets: palette entries and key entries pick the textures they apply to,
  a texture no entry names is skipped, --keys narrows;
- --dry-run writes nothing; the tunables are data (a preset's override
  changes the result); a bake into pc/assets and a preview outside pc/build
  are refused; a second bake rewrites nothing.
"""
import json
import pathlib
import sys
import tempfile

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
import material_bake as mb  # noqa: E402

failures = []


def check(ok, message):
    print(("ok:   " if ok else "FAIL: ") + message, flush=True)
    if not ok:
        failures.append(message)


def wall(w=48, h=40):
    """Blocks 16 x 10 texels, 2-texel mortar, a left-to-right shading gradient, noise."""
    rng = np.random.default_rng(1)
    y, x = np.mgrid[0:h, 0:w]
    offset = (y // 10 % 2) * 8
    mortar = ((x + offset) % 16 < 2) | (y % 10 < 2)
    lum = np.where(mortar, 0.18, 0.72) + 0.25 * (x / w - 0.5) + rng.choice([-0.04, 0, 0.04], (h, w))
    rgb = np.stack([lum, lum * 0.95, lum * 0.85], -1)
    rgba = np.concatenate([np.clip(rgb, 0, 1), np.ones((h, w, 1))], -1)
    return (rgba * 255).astype(np.uint8), mortar


def iron(w=32, h=32):
    rgba = np.full((h, w, 4), 255, np.uint8)
    rgba[..., :3] = (150, 150, 155)
    rgba[:, :10, :3] = (140, 70, 30)  # rust down the left
    return rgba


def main():
    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        tex = tmp / "tex"
        tex.mkdir()
        img, mortar = wall()
        Image.fromarray(img, "RGBA").save(tex / "aaaaaaaaaa-48x40-1111111111.png")
        Image.fromarray(iron(), "RGBA").save(tex / "bbbbbbbbbb-32x32-direct.png")
        Image.fromarray(img, "RGBA").save(tex / "cccccccccc-48x40-2222222222.png")  # no entry
        catalog = tmp / "catalog.json"
        catalog.write_text(json.dumps({"presets": {"stone": {"roughness": 0.7, "metal": 0},
                                                   "worn iron": {"roughness": 0.55, "metal": 1}},
                                       "entries": [{"id": "M1", "match": {"clut": "1111111111"}, "preset": "stone"},
                                                   {"id": "M2", "match": {"key": "bbbbbbbbbb", "size": [32, 32]},
                                                    "preset": "worn iron"}]}))
        presets, entries = mb.read_catalogs([catalog, tmp / "absent.json"])
        found = mb.find_textures(tex, None)
        todo = mb.targets(found, presets, entries)
        check(sorted(todo) == ["aaaaaaaaaa", "bbbbbbbbbb"], f"targets: palette and key entries, unnamed skipped: {sorted(todo)}")
        check(sorted(mb.targets(found, presets, entries, {"bbbbbbbbbb"})) == ["bbbbbbbbbb"], "--keys narrows")

        out = tmp / "baked"
        config = mb.load_config()
        mb.bake(todo, config, out, dry_run=True, log=lambda *a: None)
        check(not out.exists(), "--dry-run writes nothing")
        mb.bake(todo, config, out, log=lambda *a: None)
        stone = out / "aaaaaaaaaa"
        names = sorted(p.name for p in stone.iterdir())
        check(names == ["height.png", "roughness.png"], f"stone: height and roughness, no metal: {names}")
        ims = {n: Image.open(stone / n) for n in names}
        check(all(i.mode == "L" and i.size == (48, 40) for i in ims.values()), "8-bit grayscale at the texture's size")
        height = np.asarray(ims["height.png"]).astype(float)
        rough = np.asarray(ims["roughness.png"]).astype(float)
        inner = ~mortar
        for _ in range(1):  # the blocks' inner texels (away from the seams)
            inner = inner & np.roll(inner, 1, 0) & np.roll(inner, -1, 0) & np.roll(inner, 1, 1) & np.roll(inner, -1, 1)
        check(height[mortar].mean() < height[inner].mean() - 30,
              f"mortar below the blocks: {height[mortar].mean():.1f} vs {height[inner].mean():.1f}")
        check(abs(height.mean() - 128) < 12, f"height mean near 128: {height.mean():.1f}")
        left, right = height[:, 4:20][inner[:, 4:20]].mean(), height[:, 28:44][inner[:, 28:44]].mean()
        check(abs(left - right) < 12, f"the painted shading is no slope: blocks left {left:.1f}, right {right:.1f}")
        check(height[inner].std() < 18, f"no speckle on the blocks: spread {height[inner].std():.1f}")
        check(rough[mortar].mean() > rough[inner].mean(), "the seams are rougher")
        lo, hi = config["presets"].get("stone", {}).get("roughness_range", config["default"]["roughness_range"])
        check(rough.min() >= lo * 255 - 1 and rough.max() <= hi * 255 + 1, "roughness within the preset's range")

        metal = np.asarray(Image.open(out / "bbbbbbbbbb" / "metal.png")).astype(float)
        check(metal[:, 14:].mean() > 150 and metal[:, :10].max() == 0,
              f"iron: metal where grey ({metal[:, 14:].mean():.0f}), none on the rust ({metal[:, :10].max():.0f})")

        stamps = {p: p.stat().st_mtime_ns for p in out.rglob("*.png")}
        mb.bake(todo, config, out, log=lambda *a: None)
        check(all(p.stat().st_mtime_ns == s for p, s in stamps.items()), "a second bake rewrites nothing")

        tuned = json.loads(json.dumps(config))
        tuned["presets"]["stone"] = {"height_amplitude": 0.0}
        flat = mb.bake({"aaaaaaaaaa": todo["aaaaaaaaaa"]}, tuned, out, dry_run=True, log=lambda *a: None)
        check(np.all(flat["aaaaaaaaaa"]["height"] == 128), "the tunables are data: amplitude 0 is flat")

        check(mb.main(["--all", "--catalog", str(catalog), "--user-catalog", str(tmp / "none.json"), "--textures",
                       str(tex), "--exports", str(tmp / "none"), "--out", str(ROOT / "pc/assets/materials")]) == 2,
              "a bake into pc/assets is refused")
        check(mb.main(["--all", "--catalog", str(catalog), "--user-catalog", str(tmp / "none.json"), "--textures",
                       str(tex), "--exports", str(tmp / "none"), "--out", str(out), "--dry-run",
                       "--preview", str(tmp / "preview")]) == 2, "a preview outside pc/build is refused")
    if failures:
        print(f"{len(failures)} failure(s)")
        return 1
    print("material_bake: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
