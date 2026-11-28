#!/usr/bin/env python3
"""The PhotoCraft painter without PhotoCraft or the game: the control protocol's handshake against a fake server, the .psd the export writes (read
back), the swatches, a group's picture turned into the game's map, the live link's polling against a fake PhotoCraft (revision settling, only the
changed channel pushed, a save imported, closing ending the link).

    python3 pc/tests/photocraft_test.py"""
import argparse
import hashlib
import hmac
import json
import pathlib
import socketserver
import struct
import sys
import tempfile
import threading
import time

import numpy as np
from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from photocraft_fixture import make_package  # noqa: E402
import paint_live  # noqa: E402
import paint_photocraft as pp  # noqa: E402
import paint_roundtrip as pr  # noqa: E402
import photocraft_ctl as ctl  # noqa: E402
import psd_io  # noqa: E402

failures = 0


def check(ok, message):
    global failures
    print(("ok:   " if ok else "FAIL: ") + message)
    failures += not ok


TOKEN = "ab" * 32


class FakeServer(socketserver.ThreadingTCPServer):
    """A PhotoCraft's control port: the challenge handshake (holding TOKEN) and a few commands over fake documents:
    self.docs = [{"path", "revision", "layers": [{"id", "name", "visible"}...]}], self.active = index."""
    allow_reuse_address = True
    daemon_threads = True

    def __init__(self, token=TOKEN):
        class Handler(socketserver.StreamRequestHandler):
            def handle(h):
                authed, cnonce, snonce = False, None, None
                for line in h.rfile:
                    req = json.loads(line)
                    m, p, i = req["method"], req.get("params") or {}, req["id"]
                    self.log.append(m if m != "engine.execute" else p["command"])

                    def reply(result=None, error=None):
                        h.wfile.write((json.dumps({"id": i, "ok": error is None, **({"result": result} if error is None else {"error": error})}) + "\n").encode())
                    if m == "auth.challenge":
                        cnonce, snonce = p["clientNonce"], "cd" * 32
                        reply({"serverNonce": snonce, "serverProof": hmac.new(self.token.encode(), f"photocraft-control-v1 server\n{cnonce}\n{snonce}".encode(), hashlib.sha256).hexdigest()})
                    elif m == "auth":
                        want = hmac.new(self.token.encode(), f"photocraft-control-v1 client\n{cnonce}\n{snonce}".encode(), hashlib.sha256).hexdigest()
                        authed = hmac.compare_digest(p.get("proof", ""), want)
                        reply({"authenticated": True}) if authed else reply(error="authentication required")
                    elif not authed:
                        reply(error="authentication required")
                        return
                    else:
                        self.handle_request(m, p, reply)
        self.token, self.log, self.docs, self.active = token, [], [], 0
        super().__init__(("127.0.0.1", 0), Handler)
        threading.Thread(target=self.serve_forever, daemon=True).start()

    def handle_request(self, method, p, reply):
        if method == "app.save":
            reply({"path": p.get("path"), "warnings": []})
            return
        c, q = p["command"], p.get("params") or {}
        if c == "document.inspect":
            i = q.get("document", self.active)
            if not self.docs:
                return reply(error="command `document.inspect` is not available right now: no document open")
            if i >= len(self.docs):
                return reply(error=f"no document at index {i}")
            doc = self.docs[i]
            return reply({"path": doc["path"], "revision": doc["revision"], "layers": doc["layers"], "history": doc.get("history", ["Open"]),
                          "canUndo": len(doc.get("history", ["Open"])) > 1, "canRedo": False})
        reply(error=f"unknown command {c}")


with tempfile.TemporaryDirectory() as d:
    d = pathlib.Path(d)
    # ---------------------------------------------------------------- the handshake
    server = FakeServer()
    port = server.server_address[1]
    tokfile = d / "token"
    tokfile.write_text(TOKEN + "\n")
    conn = ctl.Control(port, tokfile)
    check(server.log[:2] == ["auth.challenge", "auth"], f"the client opens with the challenge, then its proof: {server.log[:2]}")
    bad = None
    try:
        ctl.Control(port, "00" * 32)
    except ctl.CtlError as e:
        bad = str(e)
    check(bad is not None and "does not hold the token" in bad, "a server that cannot prove it holds the token is not trusted (no proof is sent)")
    refused = None
    try:
        conn.execute("nothing.here")
    except ctl.CtlError as e:
        refused = str(e)
    check(refused == "unknown command nothing.here", f"a refused command is a CtlError with the server's message: {refused}")
    try:
        ctl.Control(1, tokfile)
    except ctl.CtlError as e:
        check("not reachable" in str(e), "an unreachable port is a CtlError")

    # ---------------------------------------------------------------- the .psd the export writes
    pkg = make_package(d)
    psd = pkg / "photocraft" / "aaaaaaaaaa_g100.psd"
    raw = psd.read_bytes()
    check(raw[:4] == b"8BPS" and struct.unpack(">HIIHH", raw[12:26]) == (3, 6, 8, 8, 3), "a PSD of the texture's size, 8-bit RGB")
    for text in ("Game colour (reference)", "Height", "Metal", "Roughness", "</Layer group>", "Metal from the game"):
        check(text.encode("utf-16-be") in raw, f"the file names {text!r}")
    check(raw.count(b"8BIMlspf") == 1, "one layer is locked (the game's colour)")
    check((pkg / "photocraft" / "aaaaaaaaaa_g200.psd").exists() and not (pkg / "aseprite").exists(), "a file per material, and no .aseprite files")
    flat = psd_io.flat([{"name": "a", "pixels": np.full((2, 2, 4), (10, 20, 30, 128), np.uint8)}], 2, 2)
    check(flat[0, 0].tolist() == [132, 137, 142], f"the merged image is the layers over white: {flat[0, 0].tolist()}")
    aco = psd_io.aco([(255, 255, 255, "Worn steel: Metal 1.00")])
    check(aco[:4] == struct.pack(">HH", 1, 1) and "Worn steel: Metal 1.00".encode("utf-16-be") in aco, "a swatch file (version 1 then 2 with names)")

    # ---------------------------------------------------------------- swatches
    entries = pp.swatch_entries([{"name": "Worn steel", "metal": 1.0, "roughness": 0.42}, {"name": "Plain", "roughness": 1.0}])
    check([e[3] for e in entries] == ["Worn steel: Metal 1.00", "Worn steel: Roughness 0.42", "Plain: Roughness 1.00"] and entries[1][:3] == (107, 107, 107),
          f"a gray swatch per preset and channel it sets: {entries}")

    # ---------------------------------------------------------------- a group's picture as the game's map
    was = np.full((2, 3), 100, np.uint8)
    render = np.zeros((2, 3, 4), np.uint8)
    render[0, 0] = (255, 255, 255, 255)   # opaque white: 255
    render[0, 1] = (255, 255, 255, 128)   # half: halfway to white from 100
    render[0, 2] = (100, 100, 100, 255)   # opaque, at the game's value: untouched
    render[1, 0] = (0, 0, 0, 0)           # transparent: the game's
    c = pp.canvas_of(render, was)
    check(c[0, 0].tolist() == [255, 255, 255, 255], "opaque paint is its gray")
    check(c[0, 1, 3] == 255 and c[0, 1, 0] == int(round(255 * 128 / 255 + 100 * (1 - 128 / 255))), f"a partly transparent pixel is mixed with the game's value: {c[0, 1].tolist()}")
    check(c[0, 2, 3] == 0 and c[1, 0, 3] == 0, "a pixel at the game's value, or transparent, stays transparent (the game's)")
    check(pr.layered_map(c, was)[0].tolist() == [255, 178, 100] and pr.layered_map(c, was)[1, 0] == 100, f"the import's layered_map reads it: {pr.layered_map(c, was).tolist()}")

    # ---------------------------------------------------------------- words for the two causes, and one socket named twice
    check("dialog" in pp.explain(ctl.CtlError("command is unavailable while a modal dialog is open")) and "minimised" not in pp.explain(ctl.CtlError("command is unavailable while a modal dialog is open")), "a modal dialog is named as one cause")
    check("minimised" in pp.explain(ctl.CtlError("timeout: no reply in 60s")) and "dialog" not in pp.explain(ctl.CtlError("timeout: no reply in 60s")), "a timeout is named as the other (a window that is not drawing)")
    sock = d / "rpc.sock"
    sock.write_text("")
    here = pathlib.Path.cwd()
    import os
    os.chdir(d)
    try:
        check(pr.with_game_socket([str(sock)], "rpc.sock") == [str(sock)], "the game's socket named relatively beside the same one named absolutely is listed once")
        b2 = paint_live.Bridge(make_package(d, "dup"), rpc=[str(sock), "rpc.sock"], layer=str(d / "l"), catalog=str(d / "c.json"))
        check(len(b2.rpcs) == 1, "the bridge pushes to one socket named twice once")
    finally:
        os.chdir(here)

    # ---------------------------------------------------------------- the link against a fake PhotoCraft
    pkg = make_package(d, "link")
    bridge = paint_live.Bridge(pkg, rpc=["/nonexistent/x.sock"], layer=str(d / "layer"), catalog=str(d / "cat.json"))
    pushed = []
    bridge.push = lambda key, obj, channel, array: pushed.append((channel, array.copy())) or True
    server.docs = [{"path": str((pkg / "photocraft" / "aaaaaaaaaa_g100.psd").resolve()), "revision": 1, "layers": [], "history": ["Open"]},
                   {"path": str((pkg / "photocraft" / "aaaaaaaaaa_g200.psd").resolve()), "revision": 1, "layers": [], "history": ["Open"]}]
    renders = []
    state = {"metal": 0, "others": "a"}

    def fake_render(conn_, headless_, size, folder, tag):
        renders.append(tag)
        h, w = size
        out = {c: np.zeros((h, w, 4), np.uint8) for c in ("height", "metal", "roughness")}
        out["metal"][:, :2] = (255, 255, 255, 255) if state["metal"] else (0, 0, 0, 0)
        return out, {"Layer 1": state["others"]}
    real_render = pp.render_groups
    pp.render_groups = fake_render
    clock = {"t": 0.0}
    log = []
    link = pp.PhotoCraftLink(pkg, bridge, ctl.Control(port, tokfile), say=log.append, now=lambda: clock["t"])

    def look(seconds=0.0):
        clock["t"] += seconds
        return link.step()
    try:
        look()
        look(pp.SETTLE + 0.01)
        check(renders == ["aaaaaaaaaa_g100"] and not pushed, f"the first look draws the active document once; nothing painted, nothing pushed: {renders}")
        server.active = 1
        look(0.1)
        look(pp.SETTLE + 0.01)
        check(sorted(renders) == ["aaaaaaaaaa_g100", "aaaaaaaaaa_g200"] and not pushed, "...and the other when it becomes the active one (only the active document can be copied)")
        renders.clear()
        server.active = 0
        look(1)
        # selecting a layer, zooming, hiding for a look: the revision moves, the history does not
        server.docs[0]["revision"] = 2
        look(1)
        look(pp.SETTLE + 1)
        check(not renders, "a layer selected (the revision moves, the history does not) draws nothing")
        server.docs[0]["history"] = ["Open", "Brush Tool"]
        server.docs[0]["revision"] = 3
        look(1)
        check(not renders, "a content edit is not drawn at once (a stroke may follow): the history has to hold still")
        server.docs[0]["history"] = ["Open", "Brush Tool", "Brush Tool"]
        look(pp.SETTLE - 0.1)
        check(not renders, "...and an edit that follows starts the wait over")
        state["metal"] = 1
        look(pp.SETTLE + 0.01)
        check(renders == ["aaaaaaaaaa_g100"] and [p[0] for p in pushed] == ["metal"], f"a settled edit draws that document and pushes only the channel that changed: {renders}, {[p[0] for p in pushed]}")
        check(any("after 'Brush Tool'" in line and "metal 12 pixels" in line for line in log), f"...and the log says what changed: {log[-2:]}")
        check((pushed[0][1][:, :2] == 255).all() and np.array_equal(pushed[0][1][:, 2:], np.tile(np.arange(2, 8, dtype=np.uint8) * 20, (6, 1))), "...the painted texels 255, the game's metal elsewhere")
        server.docs[0]["history"].append("Brush Tool")
        look(1)
        look(pp.SETTLE + 0.01)
        check(len(pushed) == 1 and any("no map changed" in line and "Height, Metal or Roughness" in line for line in log), "an edit that draws the same maps pushes nothing and says so")
        # an edit outside the groups: named
        state["others"] = "b"
        server.docs[0]["history"].append("Brush Tool")
        log.clear()
        look(1)
        look(pp.SETTLE + 0.01)
        check(any("'Layer 1' changed outside the Height, Metal, Roughness groups: only strokes inside" in line for line in log), f"a change outside the channel groups is named: {log}")
        # a document that is not active waits
        renders.clear()
        server.docs[1]["history"] = ["Open", "Brush Tool"]
        look(1)
        look(pp.SETTLE + 0.01)
        check(not renders, "an edit in a document that is not the active one waits for it to be")
        server.active = 1
        look(0.1)
        check(renders == ["aaaaaaaaaa_g200"], "...and is drawn when it is")
        server.active = 0
        # a save: the file's stamp moves while the document is open: the maps are kept and imported (no new drawing when nothing changed since)
        renders.clear()
        (pkg / "photocraft" / "aaaaaaaaaa_g100.psd").write_bytes((pkg / "photocraft" / "aaaaaaaaaa_g100.psd").read_bytes() + b"\0")
        look(1)
        saved = sorted(p.relative_to(d / "layer").as_posix() for p in (d / "layer").rglob("*.png"))
        check(saved == ["aaaaaaaaaa/@g100/metal.png"] and not renders, f"a save imports the painted channel only, from the last drawing: {saved}")
        check((np.asarray(Image.open(d / "layer/aaaaaaaaaa/@g100/metal.png"))[:, :2] == 255).all(), "...as the picture drew it")
        check(any("saved" in line and "metal imported" in line for line in log), f"...and says so: {log[-1:]}")
        other = d / "layer2"
        pr.import_package(argparse.Namespace(dir=str(pkg), layer=str(other), catalog=str(d / "cat2.json"), normal_format="auto", keep_seed=False))
        check(sorted(p.relative_to(other).as_posix() for p in other.rglob("*.png")) == ["aaaaaaaaaa/@g100/metal.png"], "`import` reads the maps the last save kept")
        check(look() is True, "the link goes on while a document is open")
        server.docs.clear()
        check(look(1) is False, "the link ends when the package's documents are all closed")
    finally:
        pp.render_groups = real_render
    server.shutdown()
    # an unpainted package imports to nothing (as the Aseprite flow's)
    pkg2 = make_package(d, "quiet")
    quiet = d / "layer3"
    pr.import_package(argparse.Namespace(dir=str(pkg2), layer=str(quiet), catalog=str(d / "cat3.json"), normal_format="auto", keep_seed=False))
    check(not quiet.exists() or not list(quiet.rglob("*.png")), "an unpainted export imports to nothing")
    check(not (pkg2 / "photocraft" / "saved").exists(), "...and the link keeps nothing before a save")

    # ---------------------------------------------------------------- a model's page (an atlas): the game's maps only where the boxes are
    boxes = [{"key": "bbbbbbbbbb", "box": [0, 0, 7, 5], "rgba": np.full((6, 8, 4), 200, np.uint8)},
             {"key": "cccccccccc", "box": [16, 8, 23, 13], "rgba": np.full((6, 8, 4), 90, np.uint8)}]
    bake = d / "atlasbake" / "cccccccccc" / "@m4b8870d7"
    bake.mkdir(parents=True)
    Image.fromarray(np.full((6, 8), 77, np.uint8), "L").save(bake / "metal.png")
    textures = {"m4b8870d7_p16_c0005": {"w": 256, "h": 256, "box": [0, 0, 255, 255], "object": "m4b8870d7", "model": "4b8870d7", "atlas": boxes}}
    apkg = d / "apkg"
    apkg.mkdir()
    positions = np.zeros((1, 3, 3), np.float32)
    tris = [{"tpage": 16, "clut": 5, "group": 0, "flags": 0, "uv": [[0, 0], [7, 0], [16, 8]], "polygon": 0}]
    pr.write_package(apkg, positions, np.full((1, 3, 3), 0.5, np.float32), tris, [{"key": "bbbbbbbbbb"}], textures, ["m4b8870d7_p16_c0005"],
                     {}, {"target": "model", "model": "4b8870d7"}, [d / "atlasbake"], photocraft=True)
    check([p.name for p in (apkg / "photocraft").glob("*.psd")] == ["m4b8870d7_p16_c0005.psd"], "a model's page is one .psd")
    metal = np.zeros((256, 256, 4), np.uint8)
    metal[10:12, 18:20] = 255  # painted in the second box (at (2..3, 2..3) of it)
    pp.write_canvases(apkg, "m4b8870d7_p16_c0005", {"metal": metal})
    atlas_layer = d / "atlas-layer"
    pr.import_package(argparse.Namespace(dir=str(apkg), layer=str(atlas_layer), catalog=str(d / "cat4.json"), normal_format="auto", keep_seed=False))
    got = sorted(p.relative_to(atlas_layer).as_posix() for p in atlas_layer.rglob("*.png"))
    check(got == ["cccccccccc/@m4b8870d7/metal.png"], f"a texel painted in the page is a map of the box it lies in: {got}")
    cut = np.asarray(Image.open(atlas_layer / "cccccccccc/@m4b8870d7/metal.png"))
    check(cut.shape == (6, 8) and (cut[2:4, 2:4] == 255).all() and int((cut == 77).sum()) == 44, "...the game's metal (77) kept around it")

print(f"{failures} failed" if failures else "all passed")
sys.exit(1 if failures else 0)
