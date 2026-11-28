#!/usr/bin/env python3
"""Painting a package's materials in PhotoCraft (a layered raster editor with real layer masks; paint_roundtrip.py `paint ... --painter photocraft`).

The export writes one layered .psd per texture page into <package>/photocraft/ (paint_roundtrip.write_photocraft): the game's colour (locked) and a
group per channel of the table (Height, Metal, Roughness) holding the game's current map as a layer; where the game has no map the layer is
transparent (and stays the game's value). You paint inside the groups with whatever PhotoCraft has: brushes, fill layers, masks, blend modes.

The live link (`PhotoCraftLink`) talks to PhotoCraft's localhost control server (photocraft_ctl.py): it looks at each package document's revision
a few times a second, and when one has changed and held still it has PhotoCraft draw each channel group alone (on a throwaway copy of the document,
so the user's document is not touched), reads the picture back as the group's pixels (masks, blend modes, feather and opacity are what PhotoCraft
shows), and hands them to the live bridge as that channel's layer: a transparent pixel is the game's value, a partly transparent one is mixed with it.
Ctrl+S in PhotoCraft saves the .psd; the link sees the file change, takes the maps as they are then and imports them like the Aseprite flow does."""
import argparse
import json
import os
import pathlib
import shutil
import subprocess
import sys
import threading
import time

import numpy as np
from PIL import Image

import paint_channels as pch
import paint_roundtrip as pr
import photocraft_ctl as ctl
import psd_io

DEFAULT_PORT = 47490
POLL = 0.25  # seconds between looks at the documents' revisions
SETTLE = 0.3  # a revision must stand this long before the groups are drawn
SWATCH_GROUP = "Rood materials"
RENDER_NAME = "~rood-render"  # the throwaway copy's name


def folder_of(package):
    return pathlib.Path(package).resolve() / "photocraft"


def psd_path(package, label_safe):
    return folder_of(package) / f"{label_safe}.psd"


def swatch_entries(presets):
    """Gray swatches of the presets' values: [(r, g, b, 'Worn steel: Metal 1.00')], one per preset and channel it sets. Pick one as the colour of
    a fill layer in the channel's group (a gray's value is the map's: white is 1, black 0)."""
    out = []
    for p in presets:
        for channel in pch.PRESET_CHANNELS:
            if p.get(channel) is None:
                continue
            v = int(round(float(p[channel]) * 255))
            out.append((v, v, v, f"{p['name']}: {pch.BY_CHANNEL[channel]['layer']} {float(p[channel]):.2f}"))
    return out


def canvas_of(render, was):
    """A channel's layer canvas (RGBA, what the import and the live bridge read: transparent keeps the game's value) from PhotoCraft's picture of
    the group alone (`render`, RGBA with straight alpha) and the game's map under it (`was`, 8-bit): the group laid over the game's value, a pixel
    that comes out as the game's value transparent, any other opaque with its gray."""
    rgba = render.astype(np.float64)
    gray = (rgba[..., 0] * 299 + rgba[..., 1] * 587 + rgba[..., 2] * 114) / 1000.0
    a = rgba[..., 3] / 255.0
    mixed = np.rint(gray * a + was.astype(np.float64) * (1 - a)).astype(np.uint8)
    out = np.empty(was.shape + (4,), np.uint8)
    out[..., :3] = mixed[..., None]
    out[..., 3] = np.where(mixed != was, 255, 0)
    return out


def read_pc_channels(package, label_safe):
    """{channel: canvas} the live link kept when the .psd was last saved (render_dir), for the import; {} when it never saw a save."""
    out = {}
    for channel in pch.NAMES:
        path = render_dir(package) / f"{label_safe}.{channel}.png"
        if path.exists():
            out[channel] = (path, np.asarray(Image.open(path).convert("RGBA")))
    return out


def render_dir(package):
    return folder_of(package) / "saved"


def write_canvases(package, label_safe, canvases):
    """The channel canvases as the saved .psd has them: what a later `import` reads (no PhotoCraft needed then)."""
    folder = render_dir(package)
    folder.mkdir(parents=True, exist_ok=True)
    for channel, canvas in canvases.items():
        Image.fromarray(canvas, "RGBA").save(folder / f"{label_safe}.{channel}.png")


class Documents:
    """PhotoCraft's open documents by path, over one control connection."""

    def __init__(self, conn):
        self.conn = conn

    def listing(self):
        """[(index, path, revision)] of the open documents (document.inspect by tab index, which does not change the active one)."""
        out, i = [], 0
        while True:
            try:
                r = self.conn.execute("document.inspect", document=i)
            except ctl.CtlError as e:
                if str(e).startswith("no document at index") or str(e).endswith("no document open"):
                    return out
                raise
            out.append((i, r.get("path"), r.get("revision"), r))
            i += 1
            if i > 64:
                return out

    def active_path(self):
        try:
            return self.conn.execute("document.inspect").get("path")
        except ctl.CtlError:
            return None

    def activate(self, path):
        for i, p, _, _ in self.listing():
            if p == path:
                self.conn.execute("document.activate", document=i)
                return True
        return False


def render_groups(conn, docs, info, size, folder, tag):
    """PhotoCraft's picture of each channel group alone: {channel: RGBA array of `size` (h, w)}. A throwaway copy of the document is made (it
    becomes the active one for a moment), every top-level layer hidden except the channel's, the copy saved as a PNG (a copy, 1:1, with its
    transparency), the copy closed and the document the user had active made active again."""
    was_active = docs.active_path()
    conn.execute("image.duplicate", name=RENDER_NAME)
    out = {}
    try:
        dup = conn.execute("document.inspect")
        top = dup["layers"]
        kinds = [pch.layer_channel(node["name"]) for node in top]
        for node in top:  # (a view aid, the eye or opacity of a group, is not the map: every channel node is drawn at full)
            conn.execute("layer.setProps", layer=node["id"], visible=False)
        for channel in pch.NAMES:
            mine = [n for n, k in zip(top, kinds) if k == channel]
            if not mine:
                continue
            for node in mine:
                conn.execute("layer.setProps", layer=node["id"], visible=True, opacity=1.0)
            path = folder / f"{tag}.{channel}.png"
            conn.call("app.save", path=str(path))
            for node in mine:
                conn.execute("layer.setProps", layer=node["id"], visible=False)
            img = Image.open(path).convert("RGBA")
            path.unlink(missing_ok=True)
            if (img.height, img.width) != tuple(size):
                raise ctl.CtlError(f"the rendered {channel} is {img.width} x {img.height}, the texture {size[1]} x {size[0]}: do not resize the canvas")
            out[channel] = np.asarray(img)
    finally:
        try:
            conn.execute("file.close", save="discard")
        finally:
            if was_active:
                docs.activate(was_active)
    return out


class PhotoCraftLink:
    """The link for one package: `bridge` (paint_live.Bridge: pushes maps to the game's RPC) and `conn` (ctl.Control). `step()` is one poll."""

    def __init__(self, package, bridge, conn, say=print, now=time.monotonic):
        self.package, self.bridge, self.conn, self.say, self.now = pathlib.Path(package), bridge, conn, say, now
        self.docs = Documents(conn)
        self.by_path = {psd_path(package, pr.safe(label)): label for label in bridge.seed["labels"]}
        self.revision, self.changed_at, self.rendered = {}, {}, {}
        self.stamp = {p: self.stat(p) for p in self.by_path}  # (what is there now is not a save: only a later write is)
        self.seen_open = False
        self.render_folder = folder_of(package) / ".render"
        self.render_folder.mkdir(parents=True, exist_ok=True)
        self.canvases = {}  # label -> {channel: canvas} as last rendered

    @staticmethod
    def stat(path):
        try:
            st = path.stat()
            return st.st_mtime_ns, st.st_size
        except OSError:
            return None

    def open_paths(self):
        return {pathlib.Path(p).resolve() for _, p, _, _ in self.docs.listing() if p}

    def render(self, label):
        """The channels of a material from the open document: pushed to the game where they changed. Returns the channels pushed (count)."""
        rec = self.bridge.seed["labels"][label]
        h, w = rec["h"], rec["w"]
        path = psd_path(self.package, pr.safe(label))
        pics = render_groups(self.conn, self.docs, None, (h, w), self.render_folder, pr.safe(label))
        canvases = {}
        for channel, pic in pics.items():
            was = pr.painted_seed(self.bridge.folder, rec, channel, h, w)
            was = was if was is not None else pr.neutral_map(channel, h, w)
            canvases[channel] = canvas_of(pic, was)
        self.canvases[label] = canvases
        with self.bridge.lock:
            layers = self.bridge.layers_of(label, rec)
            changed = [c for c, cv in canvases.items() if layers.get(c) is None or not np.array_equal(layers[c], cv)]
            layers.update(canvases)
            pushed, alive = self.bridge.recompute(label, rec, changed) if changed else (0, True)
        return pushed, alive

    def save_seen(self, label, rec):
        """The .psd was saved: the maps as the document is now, kept for the import, and imported."""
        self.render(label)
        write_canvases(self.package, pr.safe(label), self.canvases.get(label, {}))
        result = pr.run_import(self.bridge.ns, only={label}, say=lambda *_: None)
        names = sorted({n for _, _, ns in result["changed"] for n in ns})
        return names

    def step(self):
        """One look: the documents' revisions (a changed one that holds still is drawn and pushed) and the files' stamps (a saved one is
        imported). Returns False once the package's documents were open and are all closed."""
        listing = self.docs.listing()
        open_now = {}
        for i, p, rev, _ in listing:
            if p and pathlib.Path(p).resolve() in self.by_path:
                open_now[pathlib.Path(p).resolve()] = rev
        if open_now:
            self.seen_open = True
        t = self.now()
        for path, rev in open_now.items():
            if self.revision.get(path) != rev:
                self.revision[path] = rev
                self.changed_at[path] = t
        for path in list(self.changed_at):
            if path not in open_now:
                del self.changed_at[path]
                continue
            if t - self.changed_at[path] < SETTLE:
                continue
            del self.changed_at[path]
            label = self.by_path[path]
            started = time.monotonic()
            try:
                pushed, alive = self.render(label)
            except ctl.CtlError as e:
                self.say(f"photocraft: {path.name}: {e}")
                continue
            self.say(f"photocraft: {time.strftime('%H:%M:%S')} {path.name}: " + (f"{pushed} maps pushed" if pushed else "no map changed")
                     + ("" if alive else " (the game is not running; the saved file still imports)") + f" ({(time.monotonic() - started) * 1000:.0f} ms)")
        for path, label in self.by_path.items():
            stamp = self.stat(path)
            if stamp != self.stamp.get(path):
                self.stamp[path] = stamp
                if stamp is None or path not in open_now:
                    continue
                try:
                    names = self.save_seen(label, self.bridge.seed["labels"][label])
                except ctl.CtlError as e:
                    self.say(f"photocraft: {path.name}: saved, but not read back ({e})")
                    continue
                self.say(f"photocraft: {time.strftime('%H:%M:%S')} {path.name} saved: " + (f"{', '.join(names)} imported" if names else "nothing changed"))
        return not (self.seen_open and not open_now)


# ----------------------------------------------------------------------------------------------------- starting PhotoCraft

def connect(port, token_file, wait=0.0):
    """A control connection to a PhotoCraft that holds the token, or None (waits up to `wait` seconds for it to come up)."""
    end = time.monotonic() + wait
    while True:
        try:
            if pathlib.Path(token_file).exists() and pathlib.Path(token_file).stat().st_size >= 64:
                return ctl.Control(port, token_file, timeout=15.0)
        except ctl.CtlError:
            pass
        if time.monotonic() >= end:
            return None
        time.sleep(0.3)


def port_free(port):
    import socket
    with socket.socket() as s:
        return s.connect_ex(("127.0.0.1", port)) != 0


def open_photocraft(package, port=None, say=print, launch=None):
    """Opens the package's .psd files in PhotoCraft with its control server on, and returns (connection, process or None). A PhotoCraft this
    package already started (its control port answers to the package's token) gets the files opened in it; else a separate PhotoCraft
    is started (--new-instance: the one you may have open is left alone) on the first free port from `port`."""
    folder = folder_of(package)
    files = sorted(folder.glob("*.psd"))
    token = folder / ".control-token"
    root = str(folder.resolve())
    candidates = [port] if port else range(DEFAULT_PORT, DEFAULT_PORT + 10)
    for p in candidates:
        conn = connect(p, token)
        if conn:
            have = Documents(conn).listing()
            have = {pathlib.Path(x[1]).resolve() for x in have if x[1]}
            for f in files:
                if f.resolve() not in have:
                    conn.call("app.open", path=str(f.resolve()))
            say(f"photocraft: PhotoCraft is already running for this package (control port {p}); its documents are used")
            return conn, None
    for p in candidates:
        if port_free(p):
            break
    else:
        raise ctl.CtlError(f"no free control port in {candidates[0]}..{candidates[-1]}")
    exe = shutil.which("photocraft")
    if not exe and not launch:
        raise ctl.CtlError("photocraft is not on the PATH")
    command = launch or [exe, "--new-instance", "--control", str(p), "--control-token-file", str(token),
                         "--automation-read-root", root, "--automation-write-root", root, *map(str, files)]
    token.parent.mkdir(parents=True, exist_ok=True)
    proc = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    conn = connect(p, token, wait=40.0)
    if not conn:
        raise ctl.CtlError("PhotoCraft did not open its control port in 40 s")
    return conn, proc


def add_swatches(conn, presets, say=print):
    """The presets' gray swatches in PhotoCraft's Swatches panel (group `Rood materials`), once: a group already there is left as it is."""
    try:
        have = conn.execute("swatches.list")
        if any(g["name"] == SWATCH_GROUP for g in have.get("groups", [])):
            return
        for r, g, b, name in swatch_entries(presets):
            conn.execute("swatches.add", color="#%02x%02x%02x" % (r, g, b), name=name, group=SWATCH_GROUP)
        say(f"photocraft: the material presets are swatches in the Swatches panel, group {SWATCH_GROUP!r} (a gray's value is the map's)")
    except ctl.CtlError as e:
        say(f"photocraft: swatches not added ({e})")


def run(args, proc=None, say=lambda text: print(text, flush=True), stop=None, conn=None):
    """The link in the foreground until PhotoCraft's documents of the package are closed (or `stop` is set / Ctrl+C)."""
    import paint_live
    import material_presets as mp
    folder = pathlib.Path(args.dir)
    rpc = list(args.rpc) if getattr(args, "rpc", None) else None
    bridge = paint_live.Bridge(folder, rpc=rpc, layer=getattr(args, "layer", None), catalog=getattr(args, "catalog", None))
    if conn is None:
        try:
            conn, proc = open_photocraft(folder, port=getattr(args, "port", None), say=say)
        except ctl.CtlError as e:
            say(f"photocraft: {e}")
            return 1
    bridge.connect()
    up = [t["rpc"] for t in bridge.targets() if t["up"]]
    say("photocraft: " + (f"painting into {', '.join(up)}" if up else "no game or studio running (the saved files still import)")
        + "; Ctrl+S in PhotoCraft keeps your work; closing the documents or Ctrl+C stops the link")
    add_swatches(conn, mp.load(), say=say)
    link = PhotoCraftLink(folder, bridge, conn, say=say)
    stop = stop or threading.Event()
    started, failures = time.monotonic(), 0
    try:
        while not stop.is_set():
            try:
                alive = link.step()
                failures = 0
            except ctl.CtlError as e:
                failures += 1
                if proc is not None and proc.poll() is not None:
                    say("photocraft: PhotoCraft closed; stopping the link")
                    break
                if failures == 1:
                    say(f"photocraft: {e} (PhotoCraft answers only while its window is drawing: not minimised or hidden); trying again")
                # (a connection that timed out is out of step with the server's replies: a new one)
                conn.close()
                fresh = connect(conn.port, conn.token_path, wait=0.0)
                if fresh is not None:
                    conn = link.conn = fresh
                    link.docs = Documents(conn)
                elif proc is None and failures > 20:
                    say("photocraft: PhotoCraft is gone; stopping the link")
                    break
                stop.wait(0.5)
                continue
            if not alive:
                say("photocraft: the documents are closed; stopping the link")
                break
            if not link.seen_open and time.monotonic() - started > 90:
                say("photocraft: PhotoCraft has not opened the package's files; stopping the link")
                break
            stop.wait(POLL)
    except KeyboardInterrupt:
        say("photocraft: stopped")
    finally:
        conn.close()
    return 0
