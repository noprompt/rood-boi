#!/usr/bin/env python3
"""Writing a layered Photoshop file (.psd: Adobe's public format, 8-bit RGB, raw channels) and Photoshop colour swatch files (.aco) with
struct and numpy only: no PhotoCraft or Photoshop needed. Used by paint_roundtrip.py to hand a material's maps to PhotoCraft.

write(path, width, height, layers): `layers` bottom to top, each a dict: name, pixels (H, W, 4) uint8 RGBA, optional visible (default True),
locked (all locks), opacity (0..255). A group is {"group": name, "layers": [...children, bottom to top], "open": True}; it nests.
The merged image (what a viewer without layers shows) is the visible layers composited over white, the layers' own pixels untouched."""
import pathlib
import struct

import numpy as np


def pascal(name, multiple=4):
    raw = name.encode("latin-1", "replace")[:255]
    out = bytes([len(raw)]) + raw
    return out + b"\0" * (-len(out) % multiple)


def block(key, data):
    data += b"\0" * (len(data) % 2)
    return b"8BIM" + key + struct.pack(">I", len(data)) + data


def unicode_name(name):
    return struct.pack(">I", len(name)) + name.encode("utf-16-be")


def records(layers, w, h, out, depth=0):
    """Appends (record bytes, channel data bytes) for each layer, in the file's order: bottom to top, a group's closing divider first."""
    for layer in layers:
        if "group" in layer:
            divider = struct.pack(">iiii", 0, 0, 0, 0) + struct.pack(">H", 4)
            chans = b"".join(struct.pack(">hI", c, 2) for c in (-1, 0, 1, 2))
            name = pascal("</Layer group>")
            infos = block(b"luni", unicode_name("</Layer group>")) + block(b"lsct", struct.pack(">I", 3))
            tail = struct.pack(">I", 0) + struct.pack(">I", 0) + name + infos
            rec = divider + chans + b"8BIMnorm" + bytes([255, 0, 0, 0]) + struct.pack(">I", len(tail)) + tail
            out.append((rec, b"\0\0" * 4))
            records(layer["layers"], w, h, out, depth + 1)
            name = pascal(layer["group"])
            infos = block(b"luni", unicode_name(layer["group"])) + block(b"lsct", struct.pack(">I", 1 if layer.get("open", True) else 2) + b"8BIMpass")
            tail = struct.pack(">I", 0) + struct.pack(">I", 0) + name + infos
            rec = struct.pack(">iiii", 0, 0, 0, 0) + struct.pack(">H", 4) + chans + b"8BIMpass" + bytes([255, 0, 0, 0]) + struct.pack(">I", len(tail)) + tail
            out.append((rec, b"\0\0" * 4))
            continue
        pix = np.ascontiguousarray(layer["pixels"], np.uint8)
        assert pix.shape == (h, w, 4), pix.shape
        chans, data = [], b""
        for cid, plane in ((-1, 3), (0, 0), (1, 1), (2, 2)):
            body = struct.pack(">H", 0) + pix[..., plane].tobytes()
            chans.append(struct.pack(">hI", cid, len(body)))
            data += body
        flags = 0 if layer.get("visible", True) else 2
        infos = block(b"luni", unicode_name(layer["name"]))
        if layer.get("locked"):
            infos += block(b"lspf", struct.pack(">I", 0x80000000))
        tail = struct.pack(">I", 0) + struct.pack(">I", 0) + pascal(layer["name"]) + infos
        rec = (struct.pack(">iiii", 0, 0, h, w) + struct.pack(">H", 4) + b"".join(chans) + b"8BIMnorm"
               + bytes([int(layer.get("opacity", 255)), 0, flags, 0]) + struct.pack(">I", len(tail)) + tail)
        out.append((rec, data))


def flat(layers, w, h, below=None):
    """The visible layers composited over white: an (H, W, 3) uint8 array."""
    canvas = np.full((h, w, 3), 255.0) if below is None else below
    for layer in layers:
        if "group" in layer:
            canvas = flat(layer["layers"], w, h, canvas)
            continue
        if not layer.get("visible", True):
            continue
        pix = layer["pixels"].astype(np.float64)
        a = pix[..., 3:4] / 255.0 * layer.get("opacity", 255) / 255.0
        canvas = pix[..., :3] * a + canvas * (1 - a)
    return canvas if below is not None else np.rint(canvas).astype(np.uint8)


def write(path, width, height, layers):
    recs = []
    records(layers, width, height, recs)
    info = struct.pack(">h", len(recs)) + b"".join(r for r, _ in recs) + b"".join(d for _, d in recs)
    info += b"\0" * (len(info) % 2)
    layer_mask = struct.pack(">I", len(info)) + info + struct.pack(">I", 0)
    merged = flat(layers, width, height)
    image = struct.pack(">H", 0) + b"".join(merged[..., i].tobytes() for i in range(3))
    head = b"8BPS" + struct.pack(">H", 1) + b"\0" * 6 + struct.pack(">HIIHH", 3, height, width, 8, 3)
    path = pathlib.Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_bytes(head + struct.pack(">I", 0) + struct.pack(">I", 0) + struct.pack(">I", len(layer_mask)) + layer_mask + image)
    tmp.replace(path)


def aco(entries):
    """A Photoshop swatch file (version 1 then 2, with names) from [(r, g, b, name)]."""
    v1 = struct.pack(">HH", 1, len(entries)) + b"".join(struct.pack(">HHHHH", 0, r * 257, g * 257, b * 257, 0) for r, g, b, _ in entries)
    v2 = struct.pack(">HH", 2, len(entries)) + b"".join(
        struct.pack(">HHHHH", 0, r * 257, g * 257, b * 257, 0) + struct.pack(">I", len(n) + 1) + n.encode("utf-16-be") + b"\0\0" for r, g, b, n in entries)
    return v1 + v2
