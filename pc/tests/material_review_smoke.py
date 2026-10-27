#!/usr/bin/env python3
"""The in-game Material review (pc/docs/Materials.md, "Reviewing in the
game"; RPC material_review, Window > Material review), on proposals made
up from the save room's own textures, with scratch catalogs:

    python3 pc/tests/material_review_smoke.py [--card pc/build/test-card1.mcd] [--out DIR]

- load: a proposals.json (three proposals: two palettes in view, one
  elsewhere) and no review state yet;
- select: the proposal's preset is previewed at once on its palette's
  texels (RPC material pick: the texel's entry is the preview, its
  roughness the preset's), never in the user layer; before (preview off):
  the texel has no material; tune changes the previewed roughness;
- highlight: the palette's texels are marked (cells > 0) and the frame
  changes (Vulkan), off again: the frame is the one before;
- decide accept: ONE entry in the scratch user layer (materials.json): the
  palette, scope rooms (both of the proposal's rooms), review "accepted",
  the tuned roughness; the review moves on to the next undecided proposal;
  reject: recorded, nothing written; review_state.json holds both, in
  material_rollout_apply.py's review format;
- resume: loading again reads the decisions and the selection back;
- go: to another room (a door) and to a room no door leads into (the
  middle of its floor grid), arriving there;
- closing the window drops the preview.
"""
import argparse
import json
import os
import pathlib
import shutil
import sys

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
sys.path.insert(0, str(ROOT / "pc/tests"))
from rood_rpc import OUT  # noqa: E402
from checkpoints import launch_at  # noqa: E402
import material_rollout_apply  # noqa: E402

EMPTY = {"format": 1, "presets": {}, "entries": []}
PRESETS = {"polished metal": {"roughness": 0.4, "specular": 0.65, "metal": 0.65},
           "worn wood": {"roughness": 0.8, "specular": 1, "metal": 0},
           "rough stone": {"roughness": 0.82, "specular": 1, "metal": 0, "auto_height": True}}


def frame(game, path):
    game.call("redraw")
    game.wait_presents(6)
    game.present_screenshot(str(path))
    return np.asarray(Image.open(path).convert("RGB")).astype(np.int32)


def settle(game):
    for _ in range(3):
        game.call("redraw")
        game.wait_presents(2)


def arrive(game, zone, room):
    for _ in range(80):
        game.run(20)
        if game.call("room_goto", action="status")["phase"] in (0, 4):
            break
    game.run(40)
    s = game.state()
    return (s["zone"], s["room"]) == (zone, room)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--card", default=os.environ.get("ROOD_TEST_CARD") or str(ROOT / "pc/build/test-card1.mcd"))
    parser.add_argument("--out", help="keep the frames and logs here")
    args = parser.parse_args()
    if not pathlib.Path(args.card).exists():
        print("SKIP: no memory card", args.card)
        return 77
    vulkan = os.environ.get("ROOD_RENDERER") == "vulkan"
    out = pathlib.Path(args.out) if args.out else OUT / "material_review"
    out.mkdir(parents=True, exist_ok=True)
    card = out / "card1.mcd"
    shutil.copyfile(args.card, card)
    shipped, user = out / "catalog.json", out / "materials.json"
    shipped.write_text(json.dumps(dict(EMPTY, presets=PRESETS)))
    user.unlink(missing_ok=True)
    rollout = out / "rollout"
    shutil.rmtree(rollout, ignore_errors=True)
    rollout.mkdir()
    (out / "lights").mkdir(exist_ok=True)
    (out / "settings.cfg").write_text("light_animation 0\ndust 0\naa off\n")
    env = {"ROOD_LIGHTS": str(out / "lights"), "ROOD_LIGHTING": str(ROOT / "lighting"), "ROOD_SCALE": "2",
           "ROOD_WINDOW": "1280x960", "ROOD_SETTINGS": str(out / "settings.cfg"),
           "ROOD_MATERIAL_CATALOG": str(shipped), "ROOD_MATERIAL_CATALOG_USER": str(user),
           "ROOD_MATERIALS": str(out / "maps"), "ROOD_MATERIALS_SHIPPED": str(out / "shipped-maps"),
           "ROOD_MATERIAL_REVIEW": str(rollout / "proposals.json")}
    os.environ.pop("ROOD_SETTINGS", None)
    socket = os.environ.get("ROOD_RPC") or f"/tmp/rood-review-smoke-{os.getpid()}.sock"
    failures = []

    def check(ok, message):
        print(("ok:   " if ok else "FAIL: ") + message, flush=True)
        if not ok:
            failures.append(message)

    game = launch_at("save_room", card=card, fast=True, log=out / "game.log", extra_env=env, socket_path=socket)
    try:
        game.call("graphics", interpolate=False, lighting_preset="low")
        game.call("graphics", ao=0, specular=1)
        game.run(20)
        state = game.state()
        zone, room = state["zone"], state["room"]
        game.call("redraw")
        game.wait_presents(4)
        s = game.call("material", action="survey", grid=96, map=True)
        textures = s["textures"]
        gw, gh = s["grid"]
        cluts = []
        for t in textures:
            if t["clut"] and t["clut"] not in cluts:
                cluts.append(t["clut"])
        check(len(cluts) >= 2, f"two palettes in view ({cluts[:4]})")
        if len(cluts) < 2:
            return 1

        def pixel_of(clut):  # a survey cell drawn with the palette, as a window pixel
            for i, index in enumerate(s["map"]):
                if index >= 0 and textures[index]["clut"] == clut:
                    gx, gy = i % gw, i // gw
                    p = game.call("material", action="pick", x=(gx + 0.5) / gw * 1280, y=(gy + 0.5) / gh * 960)
                    if p.get("valid") and p.get("clut") == clut:
                        return (gx + 0.5) / gw * 1280, (gy + 0.5) / gh * 960
            return None

        a, b = cluts[0], cluts[1]
        at_a = pixel_of(a)
        check(at_a is not None, f"a pixel of palette {a}")
        rooms = game.call("rooms")["rooms"]
        doorless = next((r for r in rooms if not r.get("entries") and r.get("floor", [0, 0])[0] > 0
                         and (r["zone"], r["room"]) != (zone, room)), None)
        other = (29, 3) if (zone, room) != (29, 3) else (9, 1)
        here = f"{zone}-{room}"
        proposals = {"format": 1, "proposals": [
            {"id": "P0001", "kind": "palette", "clut": a, "key": "", "size": None, "coverage": 2.5,
             "rooms": {here: 0.4, f"{other[0]}-{other[1]}": 0.1}, "room_names": {here: "Save room"},
             "preset": "polished metal", "confidence": "high", "reason": "test", "alternatives": ["worn wood"],
             "in_catalog": []},
            {"id": "P0002", "kind": "palette", "clut": b, "key": "", "size": None, "coverage": 1.5,
             "rooms": {here: 0.2}, "room_names": {}, "preset": "worn wood", "confidence": "low", "reason": "test",
             "alternatives": [], "in_catalog": []},
            {"id": "P0003", "kind": "palette", "clut": "0123456789", "key": "", "size": None, "coverage": 0.5,
             "rooms": {f"{other[0]}-{other[1]}": 0.3}, "room_names": {}, "preset": "rough stone",
             "confidence": "medium", "reason": "test", "alternatives": [], "in_catalog": []}]}
        (rollout / "proposals.json").write_text(json.dumps(proposals))
        game.call("material_review", action="settings", advance=True, auto_go=False)
        st = game.call("material_review", action="load")
        check(st["count"] == 3 and st["decided"] == 0 and st["path"].endswith("proposals.json"),
              f"load: 3 proposals, none decided ({st['count']}, {st['decided']}, {st['error']})")
        listing = game.call("material_review", action="list", status="undecided")
        check([p["id"] for p in listing["proposals"]] == ["P0001", "P0002", "P0003"],
              f"list sorted by coverage: {[p['id'] for p in listing['proposals']]}")
        check(game.call("material_review", action="list", confidence="low")["total"] == 1, "the confidence filter")

        st = game.call("material_review", action="select", id="P0001")
        settle(game)
        pick = game.call("material", action="pick", x=at_a[0], y=at_a[1])
        check(st["selected"]["id"] == "P0001" and pick.get("entry") == "review"
              and (pick.get("material") or [0])[0] == 102,
              f"selected: the preset previewed on the palette's texel (entry {pick.get('entry')}, "
              f"material {pick.get('material')}; roughness 0.4 = 102)")
        check(not user.exists(), "the preview is not in the user layer")
        game.call("material_review", action="preview", on=False)
        settle(game)
        pick = game.call("material", action="pick", x=at_a[0], y=at_a[1])
        check((pick.get("material") or [255, 0, 0])[:3] == [255, 0, 0],
              f"before: no material on the texel ({pick.get('material')})")
        game.call("material_review", action="preview", on=True)
        game.call("material_review", action="tune", roughness=0.3)
        settle(game)
        pick = game.call("material", action="pick", x=at_a[0], y=at_a[1])
        check((pick.get("material") or [0])[0] == 77, f"tune: roughness 0.3 previewed ({pick.get('material')})")

        lit = frame(game, out / "preview.png")
        st = game.call("material_review", action="preview", highlight=True)
        game.call("material_review", action="settings", highlight_rate=0, highlight_strength=4)
        settle(game)
        st = game.call("material_review")
        flashed = frame(game, out / "highlight.png")
        changed = int((np.abs(flashed - lit).max(2) > 8).sum())
        check(st["highlight_cells"] > 0, f"highlight: {st['highlight_cells']} texels of the palette marked")
        if vulkan:
            check(changed > 500, f"highlight: the palette's surfaces light up ({changed} pixels change)")
        game.call("material_review", action="preview", highlight=False)
        settle(game)
        back = frame(game, out / "unhighlighted.png")
        check(np.array_equal(back, lit), "highlight off: the frame is the preview's again "
              f"({int((back != lit).any(2).sum())} pixels differ)")

        st = game.call("material_review", action="decide", decision="accept")
        written = json.loads(user.read_text()) if user.exists() else {}
        entries = written.get("entries", [])
        e = entries[0] if entries else {}
        check(len(entries) == 1 and e.get("id") == f"R{a}" and e.get("match") == {"clut": a}
              and e.get("scope") == {"rooms": [[zone, room], list(other)]} and e.get("review") == "accepted"
              and e.get("preset") == "polished metal" and e.get("roughness") == 0.3,
              f"accept: one palette entry with the room list in the user layer: {entries}")
        check(st["selected"]["id"] == "P0002", f"accept moves on to the next undecided ({st['selected']['id']})")
        settle(game)
        pick = game.call("material", action="pick", x=at_a[0], y=at_a[1])
        check(pick.get("entry") == f"R{a}" or pick.get("entry") == "review",
              f"the accepted entry is live ({pick.get('entry')})")
        st = game.call("material_review", action="decide", decision="reject")
        written = json.loads(user.read_text()) if user.exists() else {}
        check(len(written.get("entries", [])) == 1 and st["selected"]["id"] == "P0003",
              f"reject: nothing written, on to P0003 ({st['selected']['id']})")
        state_file = rollout / "review_state.json"
        saved = json.loads(state_file.read_text()) if state_file.exists() else {}
        ds = {d["id"]: d for d in saved.get("decisions", [])}
        check(saved.get("kind") == "material_rollout_review" and ds.get("P0001", {}).get("decision") == "accept"
              and ds.get("P0002", {}).get("decision") == "reject" and ds["P0001"].get("entry") == f"R{a}",
              f"review_state.json records both decisions: {sorted(ds)}")
        # material_rollout_apply reads the state file as a review (into a catalog copy, never the shipped one).
        text, added, skipped = material_rollout_apply.apply(saved, json.dumps(dict(EMPTY, presets=PRESETS)))
        check(len(added) == 1 and added[0]["scope"] == {"rooms": [[zone, room], list(other)]},
              f"material_rollout_apply reads the review state ({[x.get('scope') for x in added]})")

        st = game.call("material_review", action="load")
        check(st["decided"] == 2 and st.get("selected", {}).get("id") == "P0003",
              f"resume: decisions and the selection read back ({st['decided']}, {st.get('selected', {}).get('id')})")

        st = game.call("material_review", action="go", room=list(other))
        check(arrive(game, *other), f"go: arrived in {other[0]}/{other[1]}")
        if doorless:
            dz, dr = doorless["zone"], doorless["room"]
            ok = True
            try:
                game.call("material_review", action="go", room=[dz, dr])
            except Exception as error:  # noqa: BLE001
                ok = False
                print(f"go {dz}/{dr}: {error}")
            check(ok and arrive(game, dz, dr), f"go: into {dz}/{dr}, which no door leads into (its floor's middle)")

        game.call("material_review", action="open", open=False)
        listing = game.call("material")
        check(not any(x.get("origin") == "preview" for x in listing["entries"]),
              "closing the review drops the preview")
    finally:
        game.close()
    print(f"{'FAILED' if failures else 'passed'}: {len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
