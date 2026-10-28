#!/usr/bin/env python3
"""Bake material maps from the textures themselves (pc/docs/Materials.md, "Baked maps").

    python3 pc/tools/material_bake.py --all [--dry-run] [--preview DIR]
    python3 pc/tools/material_bake.py --keys KEY[,KEY...] [--method classical]

For every texture a material entry applies to (the shipped catalog and the
user's: by key, or by palette), height.png, roughness.png and (on metal-ish
presets) metal.png at exactly the texture's box size, 8-bit grayscale,
texel for texel, into the baked layer: --out, else $ROOD_MATERIALS_BAKED,
else pc/build/materials (gitignored). The maps are derived from the game's
art: they never leave this machine and are never committed. The game reads
the layer under the shipped and the user's maps (they always win) while
the materials_baked setting is on.

The textures come from the exported references ($ROOD_MATERIAL_EXPORTS or
pc/exports/materials/<key>/reference.png) and the material rollout's
texture thumbnails (--textures, default pc/build/material_rollout/tex:
<key>-<w>x<h>-<clut>.png, as RPC material texture draws them).

Methods (--method): "classical" (default), image analysis only:

  height     the luminance, smoothed edge-preserving (a guided filter: the
             palette's dithering and quantization noise go, edges stay),
             band-split: what is broader than low_sigma (the shading painted
             into the texture) is dropped, the brick-sized band (w_detail)
             and the finer one (w_mid) kept; dark narrow features (a black
             top-hat of groove_radius: mortar, cracks, gaps) carve down
             (w_groove). Normalized robustly around 128 (height_amplitude).
  roughness  the entry's roughness, rougher where the texture is busy (the
             local contrast, roughness_detail) and in the grooves
             (roughness_cavity), smoother on the raised faces
             (roughness_height), clamped to roughness_range.
  metal      only on presets with "metal": true (worn iron, polished
             metal): the entry's metal where the texels are unsaturated and
             bright enough, never rust-coloured or in the grooves; other
             presets get no metal.png (the entry's metal, 0, applies).

The tunables are data: pc/tools/material_bake.json (--config), "default"
and per-preset overrides. Another method (a learned height estimator, say)
is one more function in METHODS taking the same texture and parameters.
--preview DIR writes contact sheets (the texture, then its maps) into DIR,
which must be under pc/build.
"""
import argparse
import json
import os
import pathlib
import re
import sys

import numpy as np
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
CONFIG = ROOT / "pc/tools/material_bake.json"
CATALOG = ROOT / "pc/assets/materials/catalog.json"
TEXTURES = ROOT / "pc/build/material_rollout/tex"
HEX10 = re.compile(r"^[0-9a-f]{10}$")
TEX_NAME = re.compile(r"^([0-9a-f]{10})-(\d+)x(\d+)-([0-9a-f]{10}|direct)\.png$")


def baked_dir():
    e = os.environ.get("ROOD_MATERIALS_BAKED")
    return pathlib.Path(e) if e else ROOT / "pc/build/materials"


def export_dir():
    e = os.environ.get("ROOD_MATERIAL_EXPORTS")
    return pathlib.Path(e) if e else ROOT / "pc/exports/materials"


def user_catalog():
    e = os.environ.get("ROOD_MATERIAL_CATALOG_USER")
    if e:
        return pathlib.Path(e)
    lights = os.environ.get("ROOD_LIGHTS")
    return (pathlib.Path(lights) if lights else ROOT / "pc/user/lighting") / "materials.json"


def inside(path, root):
    try:
        pathlib.Path(path).resolve().relative_to(pathlib.Path(root).resolve())
        return True
    except ValueError:
        return False


# ---------------------------------------------------------------- config

def load_config(path=CONFIG):
    return json.loads(pathlib.Path(path).read_text())


def params_for(config, preset):
    p = dict(config["default"])
    p.update(config.get("presets", {}).get(preset or "", {}))
    return p


# ---------------------------------------------------------------- targets

def read_catalogs(paths):
    """Presets and entries of the catalog files in order (a later entry wins)."""
    presets, entries = {}, []
    for path in paths:
        path = pathlib.Path(path)
        if not path.exists():
            continue
        j = json.loads(path.read_text())
        presets.update(j.get("presets", {}))
        entries.extend(j.get("entries", []))
    return presets, entries


def entry_matches(e, key, w, h, clut):
    m = e.get("match", {})
    if m.get("key") and m["key"] != key:
        return False
    if not m.get("key") and not m.get("clut"):
        return False
    if m.get("clut") and m["clut"] != clut:
        return False
    if m.get("size") and list(m["size"]) != [w, h]:
        return False
    return True


def surface(e, presets):
    """The entry's preset, roughness and metal (its own over its preset's)."""
    base = presets.get(e.get("preset", ""), {})
    return {"preset": e.get("preset", ""), "roughness": float(e.get("roughness", base.get("roughness", 1.0))),
            "metal": float(e.get("metal", base.get("metal", 0.0)))}


def find_textures(textures_dir, exports):
    """(key, w, h, clut or None, path) for every texture image found."""
    found = []
    if textures_dir and pathlib.Path(textures_dir).is_dir():
        for f in sorted(pathlib.Path(textures_dir).iterdir()):
            m = TEX_NAME.match(f.name)
            if m:
                clut = None if m.group(4) == "direct" else m.group(4)
                found.append((m.group(1), int(m.group(2)), int(m.group(3)), clut, f))
    if exports and pathlib.Path(exports).is_dir():
        for d in sorted(pathlib.Path(exports).iterdir()):
            ref = d / "reference.png"
            if HEX10.match(d.name) and ref.exists():
                with Image.open(ref) as im:
                    found.append((d.name, im.width, im.height, None, ref))
    return found


def targets(textures, presets, entries, keys=None):
    """One texture per key a material entry applies to: {key: {w, h, clut, path, entry, surface}}.
    A key drawn with several palettes takes the first (sorted) that an entry matches."""
    out = {}
    for key, w, h, clut, path in textures:
        if key in out or (keys and key not in keys):
            continue
        match = None
        for e in entries:
            if entry_matches(e, key, w, h, clut):
                match = e
        if match is not None:
            out[key] = {"w": w, "h": h, "clut": clut, "path": path, "entry": match.get("id", ""),
                        "surface": surface(match, presets)}
    return out


# ---------------------------------------------------------------- filters

def pad(a, r, edge):
    return np.pad(a, r, mode="wrap" if edge == "wrap" else "reflect" if min(a.shape) > r else "edge")


def box(a, r, edge):
    """Mean over a (2r+1)^2 box."""
    if r <= 0:
        return a.copy()
    p = pad(a, r, edge)
    c = np.cumsum(np.cumsum(p, 0), 1)
    c = np.pad(c, ((1, 0), (1, 0)))
    n = 2 * r + 1
    h, w = a.shape
    s = c[n:n + h, n:n + w] - c[:h, n:n + w] - c[n:n + h, :w] + c[:h, :w]
    return s / (n * n)


def gauss(a, sigma, edge):
    if sigma <= 0:
        return a.copy()
    r = max(1, int(round(sigma * 3)))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2)
    k /= k.sum()
    p = pad(a, r, edge)
    h, w = a.shape
    t = sum(k[i] * p[:, i:i + w] for i in range(2 * r + 1))
    return sum(k[i] * t[i:i + h, :] for i in range(2 * r + 1))


def guided(a, r, eps, edge):
    """Self-guided filter (He et al.): smooths flat areas, keeps edges."""
    if r <= 0:
        return a.copy()
    m = box(a, r, edge)
    var = box(a * a, r, edge) - m * m
    k = var / (var + eps)
    b = m - k * m
    return box(k, r, edge) * a + box(b, r, edge)


def morph(a, r, edge, op):
    """Grey dilation (np.maximum) or erosion (np.minimum) over a disc of radius r."""
    if r <= 0:
        return a.copy()
    p = pad(a, r, edge)
    h, w = a.shape
    out = None
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy > r * r + r:
                continue
            s = p[r + dy:r + dy + h, r + dx:r + dx + w]
            out = s.copy() if out is None else op(out, s)
    return out


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / max(e1 - e0, 1e-6), 0, 1)
    return t * t * (3 - 2 * t)


# ---------------------------------------------------------------- the classical method

def bake_classical(rgba, surf, p):
    """rgba: float32 h x w x 4 in 0..1. Returns {channel: uint8 h x w}."""
    edge = p["edge"]
    rgb, alpha = rgba[..., :3], rgba[..., 3]
    opaque = alpha > 0
    lum = rgb @ np.array([0.299, 0.587, 0.114], np.float32)
    if opaque.any():
        lum = np.where(opaque, lum, np.median(lum[opaque]))
    s = guided(lum, int(p["smooth_radius"]), float(p["smooth_eps"]), edge)
    low = gauss(s, float(p["low_sigma"]), edge)
    mid = gauss(s, float(p["mid_sigma"]), edge)
    closing = morph(morph(s, int(p["groove_radius"]), edge, np.maximum), int(p["groove_radius"]), edge, np.minimum)
    groove = np.maximum(closing - s - float(p["groove_threshold"]), 0)
    groove = gauss(groove, float(p["groove_soften"]), edge)
    h = float(p["w_detail"]) * (mid - low) + float(p["w_mid"]) * (s - mid) - float(p["w_groove"]) * groove
    h = h - h.mean()
    scale = max(np.percentile(np.abs(h), float(p["height_percentile"])), 1e-4)
    hn = np.clip(h / scale, -1, 1)  # -1 lowest .. 1 highest
    amp = float(p["height_amplitude"])
    height = 128 + 127 * amp * hn

    contrast = np.sqrt(np.maximum(box(lum * lum, 1, edge) - box(lum, 1, edge) ** 2, 0))
    contrast = np.clip(contrast / max(np.percentile(contrast, 90), 1e-4), 0, 1.5)
    cavity = np.clip(groove / max(np.percentile(groove, 98), 1e-4), 0, 1) if groove.max() > 0 else groove
    r = (surf["roughness"] + float(p["roughness_detail"]) * (contrast - contrast.mean())
         + float(p["roughness_cavity"]) * cavity - float(p["roughness_height"]) * hn * (amp > 0))
    r = np.clip(r, *p["roughness_range"])
    out = {"height": height, "roughness": r * 255}

    if p["metal"] and surf["metal"] > 0:
        mx, mn = rgb.max(-1), rgb.min(-1)
        sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
        hue = hue_of(rgb, mx, mn)
        ms = float(p["metal_saturation"])
        m = 1 - smoothstep(ms - 0.1, ms + 0.1, sat)
        m *= smoothstep(*p["metal_brightness"], mx)
        rust = (hue >= p["metal_rust_hue"][0]) & (hue <= p["metal_rust_hue"][1]) & (sat > ms * 0.6)
        m = np.where(rust, 0, m)
        m *= 1 - float(p["metal_cavity"]) * cavity
        out["metal"] = np.clip(m, 0, 1) * surf["metal"] * 255
    for k in out:
        out[k] = np.clip(np.rint(out[k]), 0, 255).astype(np.uint8)
    return out


def hue_of(rgb, mx, mn):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    d = np.maximum(mx - mn, 1e-6)
    hue = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) / 6
    return np.where(mx - mn > 1e-6, hue, 0)


METHODS = {"classical": bake_classical}


# ---------------------------------------------------------------- baking

def load_rgba(path, w, h):
    im = Image.open(path).convert("RGBA")
    if im.size != (w, h):
        raise ValueError(f"{path}: {im.size[0]}x{im.size[1]}, the texture is {w}x{h}")
    return np.asarray(im).astype(np.float32) / 255.0


def write_gray(path, values):
    """Writes when the content changed (the game reloads what changed)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        with Image.open(path) as old:
            if old.mode == "L" and old.size == (values.shape[1], values.shape[0]) and \
                    np.array_equal(np.asarray(old), values):
                return False
    Image.fromarray(values, "L").save(path)
    return True


def bake(todo, config, out, method="classical", dry_run=False, log=print):
    """Bakes every target into out/<key>/<channel>.png. Returns {key: {channel: array}}."""
    fn = METHODS[method]
    results = {}
    written = 0
    for key in sorted(todo):
        t = todo[key]
        p = params_for(config, t["surface"]["preset"])
        maps = fn(load_rgba(t["path"], t["w"], t["h"]), t["surface"], p)
        results[key] = maps
        if dry_run:
            continue
        for name, values in maps.items():
            written += write_gray(pathlib.Path(out) / key / f"{name}.png", values)
        stale = pathlib.Path(out) / key / "metal.png"
        if "metal" not in maps and stale.exists():
            stale.unlink()  # (a bake of an earlier preset)
    log(f"{len(results)} texture(s) {'would be baked' if dry_run else 'baked'} by {method}"
        + ("" if dry_run else f": {written} file(s) written into {out}"))
    return results


def contact_sheets(todo, results, dest, per_page=48, zoom=3):
    """Rows of: the texture, height, roughness, metal; labelled with key and preset."""
    dest = pathlib.Path(dest)
    dest.mkdir(parents=True, exist_ok=True)
    keys = sorted(results)
    pages = []
    for start in range(0, len(keys), per_page):
        chunk = keys[start:start + per_page]
        cols = 2
        cell_w = max(todo[k]["w"] for k in chunk) * zoom * 4 + 5 * 6
        rows = []
        for k in chunk:
            rows.append(todo[k]["h"] * zoom + 16)
        per_col = (len(chunk) + cols - 1) // cols
        col_h = [sum(rows[i * per_col:(i + 1) * per_col]) for i in range(cols)]
        sheet = Image.new("RGB", (cell_w * cols, max(col_h) + 4), (40, 40, 40))
        draw = ImageDraw.Draw(sheet)
        for c in range(cols):
            y = 2
            for k in chunk[c * per_col:(c + 1) * per_col]:
                t, maps = todo[k], results[k]
                x = c * cell_w + 4
                draw.text((x, y), f"{k} {t['surface']['preset']} {t['w']}x{t['h']}", fill=(220, 220, 220))
                y += 14
                ref = Image.open(t["path"]).convert("RGBA")
                bg = Image.new("RGBA", ref.size, (255, 0, 255, 255))
                bg.alpha_composite(ref)
                tiles = [bg.convert("RGB")]
                for name in ("height", "roughness", "metal"):
                    v = maps.get(name)
                    tiles.append(Image.fromarray(v, "L").convert("RGB") if v is not None
                                 else Image.new("RGB", ref.size, (0, 0, 0)))
                for tile in tiles:
                    tile = tile.resize((t["w"] * zoom, t["h"] * zoom), Image.NEAREST)
                    sheet.paste(tile, (x, y))
                    x += t["w"] * zoom + 6
                y += t["h"] * zoom + 2
        path = dest / f"contact-{start // per_page:03d}.png"
        sheet.save(path)
        pages.append(path)
    return pages


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    which = ap.add_mutually_exclusive_group(required=True)
    which.add_argument("--keys", help="comma-separated texture keys")
    which.add_argument("--all", action="store_true", help="every texture a material entry applies to")
    ap.add_argument("--method", default="classical", choices=sorted(METHODS))
    ap.add_argument("--config", default=str(CONFIG))
    ap.add_argument("--catalog", default=os.environ.get("ROOD_MATERIAL_CATALOG") or str(CATALOG))
    ap.add_argument("--user-catalog", default=str(user_catalog()), help="the user layer (read only)")
    ap.add_argument("--textures", default=str(TEXTURES), help="the rollout's texture thumbnails")
    ap.add_argument("--exports", default=str(export_dir()), help="exported references (<key>/reference.png)")
    ap.add_argument("--out", default=str(baked_dir()))
    ap.add_argument("--dry-run", action="store_true", help="bake, write nothing")
    ap.add_argument("--preview", metavar="DIR", help="contact sheets into DIR (under pc/build)")
    args = ap.parse_args(argv)
    out = pathlib.Path(args.out)
    if inside(out, ROOT / "pc/assets"):
        print(f"material_bake: refusing {out}: baked maps are game art and never go into pc/assets", file=sys.stderr)
        return 2
    if args.preview and not inside(args.preview, ROOT / "pc/build"):
        print(f"material_bake: --preview must be under pc/build (game art stays local)", file=sys.stderr)
        return 2
    keys = set(k.strip() for k in args.keys.split(",")) if args.keys else None
    presets, entries = read_catalogs([args.catalog, args.user_catalog])
    todo = targets(find_textures(args.textures, args.exports), presets, entries, keys)
    if keys and keys - set(todo):
        print("material_bake: no texture or no entry for " + ", ".join(sorted(keys - set(todo))), file=sys.stderr)
    if not todo:
        print("material_bake: nothing to bake (no textures found, or no entry applies to them)", file=sys.stderr)
        return 1
    results = bake(todo, load_config(args.config), out, args.method, args.dry_run)
    if args.preview:
        for page in contact_sheets(todo, results, args.preview):
            print(page)
    return 0


if __name__ == "__main__":
    sys.exit(main())
