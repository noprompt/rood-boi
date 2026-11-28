"""A tiny paint package for the PhotoCraft tests: one 8 x 6 texture on two room groups (pc/tests/aseprite_test.py's), with a game metal and
roughness map under group 0x100 and nothing under group 0x200."""
import pathlib
import sys

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
import paint_roundtrip as pr  # noqa: E402
import room_blender as rb  # noqa: E402


def make_package(d, name="pkg", photocraft=True):
    d = pathlib.Path(d)
    positions = np.array([[[0, 0, 0], [512, 0, 0], [0, 0, 512]], [[512, 0, 0], [512, 0, 512], [0, 0, 512]]], np.float32)
    colours = np.full((2, 3, 3), 0.5, np.float32)
    tris = [{"tpage": 17, "clut": 1, "group": 0, "flags": 0, "uv": [[0, 0], [7, 0], [0, 5]], "polygon": 0x108},
            {"tpage": 17, "clut": 1, "group": 1, "flags": 0, "uv": [[7, 0], [7, 5], [0, 5]], "polygon": 0x208}]
    uses = [{"key": "aaaaaaaaaa", "tpage": 17, "clut": 1, "box": [0, 0, 7, 5]}]
    found = rb.assign(tris, uses)
    groups = [{"offset": 0x100, "first": 0x108, "end": 0x128}, {"offset": 0x200, "first": 0x208, "end": 0x228}]
    textures = {"aaaaaaaaaa": {"w": 8, "h": 6, "box": [0, 0, 7, 5], "tpage": 17, "clut": 1}}
    labels, split = rb.split_shared(tris, found, groups, textures, always=True)
    base = np.zeros((6, 8, 4), np.uint8)
    base[..., :3] = (139, 98, 65)
    base[..., 3] = 255
    bake = d / "bake"
    (bake / "aaaaaaaaaa" / "@g100").mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.full((6, 8), 120, np.uint8), "L").save(bake / "aaaaaaaaaa" / "@g100" / "roughness.png")
    Image.fromarray(np.tile(np.arange(8, dtype=np.uint8) * 20, (6, 1)), "L").save(bake / "aaaaaaaaaa" / "@g100" / "metal.png")
    pkg = d / name
    pkg.mkdir()
    pr.write_package(pkg, positions, colours, tris, found, split, labels, {"aaaaaaaaaa": base}, {"target": "room", "zone": 9, "room": 17},
                     pr.seed_layers([bake]), photocraft=photocraft)
    return pkg
