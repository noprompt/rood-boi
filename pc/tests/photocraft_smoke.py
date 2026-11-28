#!/usr/bin/env python3
"""The PhotoCraft painter against a real PhotoCraft (pc/tools/paint_photocraft.py), without the game: a tiny package's .psd files are opened in
a separate PhotoCraft (--new-instance, a private settings folder and control port; a PhotoCraft you have open is not touched), and the live link
is stepped by hand: the groups drawn alone, a stroke on a layer mask, a fill layer, the pushed maps, a save and its import, closing.

    python3 pc/tests/photocraft_smoke.py

Needs `photocraft` on the PATH and a display (it opens a window for a few seconds)."""
import argparse
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import time

import numpy as np
from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from photocraft_fixture import make_package, ROOT  # noqa: E402
import paint_live  # noqa: E402
import paint_photocraft as pp  # noqa: E402
import photocraft_ctl as ctl  # noqa: E402

failures = 0


def check(ok, message):
    global failures
    print(("ok:   " if ok else "FAIL: ") + message, flush=True)
    failures += not ok


def main():
    if not shutil.which("photocraft"):
        print("skip: photocraft is not on the PATH")
        return 0
    os.environ["ROOD_PAINT_PRESETS_USER"] = os.path.join(tempfile.gettempdir(), "photocraft_smoke_no_user_presets.json")
    with tempfile.TemporaryDirectory() as d:
        d = pathlib.Path(d)
        pkg = make_package(d)
        files = sorted((pkg / "photocraft").glob("*.psd"))
        check([f.name for f in files] == ["aaaaaaaaaa_g100.psd", "aaaaaaaaaa_g200.psd"], f"a .psd per material: {[f.name for f in files]}")
        env = {**os.environ, "PHOTOCRAFT_CONFIG_DIR": str(d / "cfg")}
        launch = ["photocraft", "--new-instance", "--control", "47931", "--control-token-file", str(pkg / "photocraft" / ".control-token"),
                  "--automation-read-root", str(pkg / "photocraft"), "--automation-write-root", str(pkg / "photocraft"), str(files[0])]
        proc = subprocess.Popen(["nice", "-n", "19", "taskset", "-c", "0-1"] + launch, env=env, stdin=subprocess.DEVNULL,
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        try:
            conn = pp.connect(47931, pkg / "photocraft" / ".control-token", wait=40)
            check(conn is not None, "PhotoCraft's control port answers the challenge with the token file's token")
            wrong = None
            try:
                ctl.Control(47931, "00" * 32)
            except ctl.CtlError as e:
                wrong = str(e)
            check(wrong is not None and "does not hold the token" in wrong, f"a wrong token is refused by the handshake: {wrong}")
            bridge = paint_live.Bridge(pkg, rpc=["/nonexistent/x.sock"], layer=str(d / "layer"), catalog=str(d / "cat.json"))
            pushed, cleared = [], []
            bridge.push = lambda key, obj, channel, array: pushed.append((key, obj, channel, array.copy())) or True
            bridge.clear = lambda key, obj, channel: cleared.append((key, obj, channel)) or True
            log = []
            link = pp.PhotoCraftLink(pkg, bridge, conn, say=log.append)
            doc = conn.execute("document.inspect", document=0)
            check(pathlib.Path(doc["path"]).resolve() == files[0].resolve(), "the .psd is open in PhotoCraft")
            names = [n["name"] for n in doc["layers"]]
            check(names == ["Roughness", "Metal", "Height", "Game colour (reference)"], f"groups and the reference layer, bottom to top: {names}")
            conn.execute("layer.select", name="Game colour (reference)")
            refused = None
            try:
                conn.execute("paint.stroke", points=[[1, 1, 1], [5, 5, 1]], size=2, color="#ff0000")
            except ctl.CtlError as e:
                refused = str(e)
            check(refused is not None and "locked" in refused, f"the game's colour layer is locked (a stroke on it is refused): {refused}")
            # first look: the document is as exported: nothing changed, nothing pushed
            link.step()
            time.sleep(pp.SETTLE + 0.1)
            link.step()
            check(not pushed, f"an unpainted document pushes nothing ({len(pushed)} pushed)")
            check(len(link.canvases.get("aaaaaaaaaa@g100", {})) == 3, "...but each of the three groups was drawn alone")
            c = link.canvases["aaaaaaaaaa@g100"]
            check(not c["metal"][..., 3].any() and not c["roughness"][..., 3].any(), "...and each is the game's own value everywhere (transparent canvas)")
            # a fill layer in Metal, with a mask that reveals the left half: Metal 1.0 there
            doc = conn.execute("document.inspect", document=0)
            metal = next(n for n in doc["layers"] if n["name"] == "Metal")
            conn.execute("layer.select", layer=metal["children"][0]["id"])
            conn.execute("layer.newFillLayer.solidColor", color="#ffffff")
            conn.execute("layer.layerMask.hideAll")
            conn.execute("select.rect", x=0, y=0, width=4, height=6)
            conn.execute("layer.layerMask.revealSelection")
            doc = conn.execute("document.inspect", document=0)
            check(doc["revision"] > 1, f"the document's revision moves with an edit: {doc['revision']}")
            link.step()
            time.sleep(pp.SETTLE + 0.1)
            link.step()
            metal_pushes = [p for p in pushed if p[2] == "metal"]
            check(len(metal_pushes) >= 1 and not [p for p in pushed if p[2] != "metal"], f"only the Metal map changed, only it is pushed: {[p[2] for p in pushed]}")
            m = metal_pushes[-1][3]
            check((m[:, :4] == 255).all(), "a white fill revealed by a mask: Metal 255 under the mask")
            check(np.array_equal(m[:, 4:], np.tile(np.arange(4, 8, dtype=np.uint8) * 20, (6, 1))), "...and the game's own metal everywhere the mask hides it")
            n = len(pushed)
            link.step()
            time.sleep(pp.SETTLE + 0.1)
            link.step()
            check(len(pushed) == n, "a poll with no change pushes nothing more")
            # save: Ctrl+S writes the psd; the link imports the maps as they are
            conn.call("app.save")
            time.sleep(0.3)
            link.step()
            written = sorted(p.relative_to(d / "layer").as_posix() for p in (d / "layer").rglob("*.png"))
            check(written == ["aaaaaaaaaa/@g100/metal.png"], f"a save imports only the painted channel: {written}")
            if written:
                saved = np.asarray(Image.open(d / "layer" / "aaaaaaaaaa/@g100/metal.png"))
                check((saved[:, :4] == 255).all() and saved[:, 4:].tolist() == m[:, 4:].tolist(), "...with the mask's result")
            log.clear()
            # the user's active document is the one they had after a draw
            check(pathlib.Path(conn.execute("document.inspect")["path"]).resolve() == files[0].resolve(), "the active document is the user's again after a draw")
            check(len(conn.call("ui.inspect")["views"]) == 1, "no throwaway copy is left open")
            # closing the document stops the link
            conn.execute("file.close", save="discard")
            time.sleep(0.3)
            check(link.step() is False, "closing the package's documents ends the link")
        finally:
            try:
                conn.call("app.quit")
            except Exception:
                pass
            try:
                proc.wait(10)
            except Exception:
                proc.terminate()
    # the whole flow: paint_photocraft.run opens PhotoCraft itself (a private settings folder through the environment), adds the swatches, and ends
    # with the documents' closing
    with tempfile.TemporaryDirectory() as d:
        d = pathlib.Path(d)
        os.environ["PHOTOCRAFT_CONFIG_DIR"] = str(d / "cfg")
        pkg = make_package(d, "flow")
        out = []
        import threading
        args = argparse.Namespace(dir=str(pkg), layer=str(d / "layer"), catalog=str(d / "cat.json"), rpc=["/nonexistent/x.sock"], port=47932)
        result = []
        t = threading.Thread(target=lambda: result.append(pp.run(args, say=out.append)))
        t.start()
        conn = pp.connect(47932, pkg / "photocraft" / ".control-token", wait=60)
        check(conn is not None, "run starts a PhotoCraft with the control port and the package's token file")
        try:
            for _ in range(100):
                if any("swatches" in line for line in out):
                    break
                time.sleep(0.2)
            groups = [g["name"] for g in conn.execute("swatches.list")["groups"]]
            check(pp.SWATCH_GROUP in groups, f"the presets are swatches in PhotoCraft: {groups}")
            sw = next(g for g in conn.execute("swatches.list")["groups"] if g["name"] == pp.SWATCH_GROUP)["swatches"]
            check(any(s["name"] == "Worn steel: Metal 1.00" and s["hex"].lower() == "#ffffff" for s in sw), f"a preset's metal as a gray swatch: {[s['name'] for s in sw][:4]}")
            check(len([1 for _, p, _, _ in pp.Documents(conn).listing() if p]) == 2, "both pages are open")
            for _ in range(2):
                conn.execute("file.close", save="discard")
            t.join(30)
            check(not t.is_alive() and result == [0] and any("documents are closed" in line for line in out), f"run ends when the documents are closed: {out[-2:]}")
        finally:
            try:
                conn.call("app.quit")
            except Exception:
                pass
            conn.close()
            t.join(5)
    print(f"{failures} failed" if failures else "all passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
