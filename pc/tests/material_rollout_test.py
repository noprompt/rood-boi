#!/usr/bin/env python3
"""Disc-free checks of the material rollout tools (pc/tools/material_rollout.py,
material_rollout_apply.py), on made-up surveys and textures:

- --until today at HH:MM; the rooms still to do skip done rooms and rooms
  that failed past their retries, and --zone / --rooms narrow them;
- the look: a flat pale texture, vertical planks (streaks), a block wall
  with dark mortar seams;
- the proposals: a floor is flagstone (wet stone in a room named for rain,
  whole words only), blocks facing sideways rough stone, brown streaked
  planks worn wood, pale even walls plaster, saturated even walls cloth
  (not dark ones), near black and object-drawn textures none; organic
  surfaces: green cut-outs foliage, green floors grass, green walls moss,
  in rooms named for a forest streaked walls bark and earthy floors earth;
  stone on weak cues low confidence; the rules are tunables;
- aggregation by palette over rooms (coverage, rooms, facing hints), the
  catalog marks, proposals sorted by coverage, and the review page carries
  the data and its export;
- applying a review to a copy of the shipped catalog: an accepted palette
  decision becomes ONE palette entry scoped to its rooms (scope rooms, or
  room for one; even when the reviewer chose "global": palette entries stay
  scoped), a texture's global
  decision one unscoped entry,
  changed presets and textures, rejected and "none" add nothing, ids follow
  the catalog's, a second apply adds nothing, the catalog keeps its layout
  and still passes material_catalog_test's rules; unknown presets fail.
"""
import datetime
import json
import pathlib
import shutil
import sys
import tempfile

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
import material_rollout as mr  # noqa: E402
import material_rollout_apply as ma  # noqa: E402

failures = []


def check(ok, message):
    print(("ok:   " if ok else "FAIL: ") + message, flush=True)
    if not ok:
        failures.append(message)


def rgba(rgb, h=32, w=32):
    a = np.ones((h, w, 4))
    a[..., :3] = rgb
    return a


def main():
    # --until and the targets.
    now = datetime.datetime(2026, 10, 26, 18, 5)
    stop = mr.until_time("21:30", now)
    check(datetime.datetime.fromtimestamp(stop) == datetime.datetime(2026, 10, 26, 21, 30), "--until is today's 21:30")
    check(mr.until_time(None) is None, "no --until: no limit")
    rooms = [{"zone": z, "room": r} for z, r in [(1, 0), (2, 0), (9, 1), (9, 2), (29, 3)]]
    state = {"done": {"9-1": {}}, "failed": {"1-0": {"attempts": 2}, "2-0": {"attempts": 1}}}
    check(mr.targets(rooms, state) == [(2, 0), (9, 2), (29, 3)], "done rooms and rooms failed twice are skipped")
    check(mr.targets(rooms, state, zones={9, 29}) == [(9, 2), (29, 3)], "--zone narrows")
    check(mr.targets(rooms, state, only={(29, 3)}) == [(29, 3)], "--rooms narrows")
    check(mr.arrival_cell({"entries": 0, "floor": [12, 9]}) == [6, 0, 4, 0] and
          mr.arrival_cell({"entries": 2, "floor": [12, 9]}) is None, "rooms without doors arrive mid-floor")

    # The look.
    flat = mr.stats_of(rgba((0.8, 0.78, 0.74)))
    planks = rgba((0.45, 0.28, 0.12))
    planks[:, ::4, :3] = (0.2, 0.12, 0.05)  # dark gaps between vertical planks
    wood = mr.stats_of(planks)
    blocks = rgba((0.5, 0.48, 0.45))
    blocks[::8, :, :3] = 0.12
    blocks[:, ::8, :3] = 0.12
    noise = np.random.default_rng(1).normal(0, 0.05, blocks.shape[:2])
    blocks[..., :3] += noise[..., None]
    stone = mr.stats_of(np.clip(blocks, 0, 1))
    check(flat["contrast"] < 0.01 and flat["lum"] > 0.7 and flat["sat"] < 0.1, f"flat pale texture: {flat}")
    check(wood["streak"] > 0.9 and 15 <= wood["hue"] <= 50, f"vertical planks streak across x: {wood}")
    check(0.35 < stone["streak"] < 0.65 and stone["seams"] > 0.1, f"blocks: seams both ways: {stone}")
    clear = rgba((0, 0, 0))
    clear[..., 3] = 0
    check(mr.stats_of(clear) == {"opaque": 0.0}, "a fully transparent texture has no look")

    # The proposals.
    floor = {"floor": 0.95, "wall": 0.05, "ceiling": 0, "object": 0}
    wall = {"floor": 0.02, "wall": 0.95, "ceiling": 0.03, "object": 0}
    p = mr.propose(stone, floor)
    check(p[0] == "flagstone" and p[1] == "high", f"a floor: flagstone, high ({p})")
    p = mr.propose(stone, floor, ["Snowfly Forest: Where Soft Rains Fell"])
    check(p[0] == "wet stone", f"a floor where it rains: wet stone ({p})")
    p = mr.propose(stone, floor, ["Wine Cellar: The Hero's Winehall"])
    check(p[0] == "flagstone" and "wet stone" in p[3], f"a damp cellar floor: flagstone, wet stone offered ({p})")
    p = mr.propose(stone, wall)
    check(p[0] == "rough stone" and p[1] == "high", f"block walls: rough stone, high ({p})")
    p = mr.propose(wood, wall)
    check(p[0] == "worn wood", f"brown streaked planks: worn wood ({p})")
    p = mr.propose(flat, wall)
    check(p[0] == "plaster", f"pale even walls: plaster ({p})")
    red = mr.stats_of(rgba((0.7, 0.1, 0.12)))
    p = mr.propose(red, wall)
    check(p[0] == "cloth", f"a saturated even red wall: cloth ({p})")
    p = mr.propose(dict(red, lum=0.15), wall)
    check(p[0] != "cloth", f"dark texels' saturation is not cloth ({p})")
    p = mr.propose(stone, floor, ["Snowfly Forest: Where Soft Rains Fell", "Catacombs: Hall", "Sanctum: Niche"])
    check(p[0] == "flagstone", f"one rainy room of three is not wet stone ({p})")
    p = mr.propose(stone, wall, ["City Walls West: The Gabled Hall"])
    check(p[0] == "rough stone", f"'Walls' is not 'well': no wet stone ({p})")
    p = mr.propose(dict(stone, lum=0.01), wall)
    check(p[0] == mr.NONE, f"near black: none ({p})")
    p = mr.propose(stone, dict(wall, object=0.9))
    check(p[0] == mr.NONE and p[1] == "low", f"object lists: none, low ({p})")
    # Organic surfaces: green cut-outs are foliage, green floors grass, green walls moss; in a forest a brown
    # streaked wall is bark and an earthy floor earth; stone guesses on weak cues are low; near black is none.
    forest = ["Snowfly Forest: The Hunt Begins", "Snowfly Forest: Which Way Home"]
    leaves = dict(stone, hue=60, sat=0.8, lum=0.2, contrast=0.07, seams=0.01, opaque=0.68)
    p = mr.propose(leaves, floor, forest)
    check(p[0] == "foliage" and p[1] == "high", f"a green cut-out in a forest: foliage, high ({p})")
    p = mr.propose(leaves, wall)
    check(p[0] == "foliage", f"a green cut-out anywhere: foliage ({p})")
    turf = dict(leaves, opaque=1.0, lum=0.4, sat=0.77, hue=54)
    p = mr.propose(turf, floor, forest)
    check(p[0] == "grass" and p[1] == "high", f"a green floor in a forest: grass, high ({p})")
    p = mr.propose(turf, floor)
    check(p[0] == "grass" and p[1] == "medium", f"a green floor elsewhere: grass, medium ({p})")
    p = mr.propose(turf, wall)
    check(p[0] == "moss", f"a green wall: moss ({p})")
    trunk = dict(stone, hue=38, sat=0.23, lum=0.31, contrast=0.12, streak=0.85, seams=0.02)
    p = mr.propose(trunk, wall, forest)
    check(p[0] == "bark", f"a streaked wall in a forest: bark ({p})")
    soil = dict(stone, hue=45, sat=0.72, lum=0.36, contrast=0.1, seams=0.02)
    p = mr.propose(soil, floor, forest)
    check(p[0] == "earth", f"an earthy floor in a forest: earth ({p})")
    p = mr.propose(stone, floor, forest)
    check(p[0] == "flagstone" and p[1] != "high", f"grey blocks in a forest stay stone, not high ({p})")
    even = dict(stone, contrast=0.03, seams=0.0, rough=0.02)
    p = mr.propose(even, wall)
    check(p[0] == "rough stone" and p[1] == "low", f"a wall with weak cues: rough stone, low ({p})")
    p = mr.propose(even, floor)
    check(p[0] == "flagstone" and p[1] == "low", f"a floor with weak cues: flagstone, low ({p})")
    p = mr.propose(dict(stone, lum=0.05), floor)
    check(p[0] == mr.NONE, f"near black (0.05): none ({p})")
    p = mr.propose(stone, dict(floor, object=0.55))
    check(p[0] == mr.NONE, f"mostly object lists: none ({p})")
    tight = dict(mr.load_rules(), void_lum=0.01)
    p = mr.propose(dict(stone, lum=0.05), floor, rules=tight)
    check(p[0] != mr.NONE, f"the rules are tunables: void_lum 0.01 keeps 0.05 ({p})")
    check(all(mr.propose(s, h, n)[0] in mr.PRESETS + [mr.NONE] for s in (flat, wood, stone, leaves, turf, trunk, soil)
              for h in (floor, wall) for n in ((), forest)),
          "every proposal is a shipped preset or none")
    shipped = json.loads((ROOT / "pc/assets/materials/catalog.json").read_text())["presets"]
    check(set(mr.PRESETS) <= set(shipped), "the rollout's presets are the catalog's")

    with tempfile.TemporaryDirectory() as tmp:
        out = pathlib.Path(tmp)
        for d in ("rooms", "tex", "views"):
            (out / d).mkdir()
        (out / "rooms.json").write_text(json.dumps([{"zone": 29, "room": 3, "area": "The Keep", "name": "Studded"},
                                                    {"zone": 9, "room": 1, "area": "Wine Cellar", "name": "Hall"},
                                                    {"zone": 9, "room": 2, "area": "Wine Cellar", "name": "Gallery"}]))

        def tex(key, clut, share, facing, obj=0, entry=""):
            return {"key": key, "size": [32, 32], "clut": clut, "share": share,
                    "facing": [share * f for f in facing], "object": obj * share, "entry": entry}

        surveys = {
            (29, 3): [tex("aaaaaaaaaa", "1111111111", 0.3, (1, 0, 0), entry="M013"),
                      tex("bbbbbbbbbb", "2222222222", 0.4, (0, 1, 0))],
            (9, 1): [tex("aaaaaaaaaa", "1111111111", 0.2, (1, 0, 0)), tex("cccccccccc", "1111111111", 0.1, (1, 0, 0)),
                     tex("dddddddddd", "", 0.05, (0, 1, 0))],
            (9, 2): [tex("bbbbbbbbbb", "2222222222", 0.5, (0, 1, 0))],
        }
        for (z, r), ts in surveys.items():
            (out / "rooms" / f"{z}-{r}.json").write_text(json.dumps({"room": [z, r], "textures": ts}))
        from PIL import Image
        Image.fromarray((np.clip(blocks, 0, 1) * 255).astype(np.uint8)).save(out / "tex" / "bbbbbbbbbb-32x32-2222222222.png")
        Image.fromarray((np.clip(blocks, 0, 1) * 255).astype(np.uint8)).save(out / "tex" / "aaaaaaaaaa-32x32-1111111111.png")
        cat = out / "catalog.json"
        cat.write_text(json.dumps({"format": 1, "presets": shipped, "entries": [
            {"id": "M013", "match": {"clut": "1111111111"}, "scope": {"room": [29, 3]}, "preset": "flagstone"}]}))
        data = mr.build(out, cat)
        q = data["proposals"]
        check([p["clut"] for p in q] == ["2222222222", "1111111111", ""], f"proposals by coverage: "
              f"{[(p['clut'], p['coverage']) for p in q]}")
        walls, floors, direct = q
        check(walls["coverage"] == 0.9 and set(walls["rooms"]) == {"29-3", "9-2"} and walls["preset"] == "rough stone",
              f"the walls' palette: two rooms, 0.9 coverage, rough stone ({walls['preset']}, {walls['reason']})")
        check(floors["hints"]["floor"] == 1 and floors["preset"] in ("flagstone", "wet stone") and
              len(floors["textures"]) == 2 and floors["in_catalog"] == ["M013"],
              f"the floors' palette: up-facing, two textures, M013 noted ({floors['preset']}, {floors['in_catalog']})")
        check(direct["kind"] == "texture" and direct["key"] == "dddddddddd" and "no thumbnail" in direct["reason"],
              f"a 15-bit texture: its own proposal, facing only ({direct['reason']})")
        check([p["id"] for p in q] == ["P0001", "P0002", "P0003"] and data["rooms_surveyed"] == 3,
              "proposal ids and the room count")
        html_page = mr.page(data)
        check("material_rollout_review" in html_page and "P0001" in html_page and "</script>" not in
              json.dumps(data).replace("</", "<\\/") and "tex/${t.id}.png" in html_page,
              "the review page embeds the proposals, the thumbnails' paths and the export")

    # Applying a review to a copy of the shipped catalog.
    text = (ROOT / "pc/assets/materials/catalog.json").read_text()
    before = json.loads(text)
    review = {"format": 1, "kind": "material_rollout_review", "decisions": [
        {"id": "P0001", "decision": "accept", "kind": "palette", "clut": "2222222222", "proposed": "rough stone",
         "preset": "rough stone", "scope": "rooms", "rooms": [[29, 3], [9, 2]], "room_names": {"9-2": "Wine Cellar"},
         "coverage": 0.9},
        {"id": "P0002", "decision": "accept", "kind": "palette", "clut": "1111111111", "proposed": "flagstone",
         "preset": "wet stone", "changed": True, "scope": "global", "rooms": [[9, 1]], "note": "Cellar floor"},
        {"id": "P0003", "decision": "accept", "kind": "texture", "clut": "", "key": "dddddddddd", "size": [32, 32],
         "proposed": "plaster", "preset": "plaster", "scope": "global", "rooms": [[9, 1]]},
        {"id": "P0004", "decision": "reject", "kind": "palette", "clut": "3333333333", "preset": "cloth",
         "rooms": [[1, 0]]},
        {"id": "P0005", "decision": "accept", "kind": "palette", "clut": "4444444444", "preset": "none",
         "rooms": [[1, 0]]},
        # already shipped: M012 is the Keep walls' palette in 29/3
        {"id": "P0006", "decision": "accept", "kind": "palette", "clut": "97ad08ce0c", "preset": "rough stone",
         "scope": "rooms", "rooms": [[29, 3]]},
    ]}
    new, added, skipped = ma.apply(review, text)
    after = json.loads(new)
    top = max(int(e["id"][1:]) for e in before["entries"])
    check(len(added) == 3 and skipped == 1, f"3 entries added, the shipped one skipped ({len(added)}, {skipped})")
    check([e["id"] for e in added] == [f"M{top + i:03d}" for i in range(1, 4)], f"ids follow the catalog's: "
          f"{[e['id'] for e in added]}")
    a, g, t = added
    check(a["match"] == {"clut": "2222222222"} and a["scope"] == {"rooms": [[29, 3], [9, 2]]}
          and "Wine Cellar" in a["where"] and "2 rooms" in a["where"],
          f"a palette in two rooms: one palette entry with the room list ({a.get('scope')})")
    check(g["preset"] == "wet stone" and g["scope"] == {"room": [9, 1]} and g["name"] == "Cellar floor" and
          "over flagstone" in g["where"], "a changed preset named by the note; a global palette stays room-scoped")
    check(t["match"] == {"key": "dddddddddd", "size": [32, 32]} and "scope" not in t and "everywhere" in t["where"],
          "a 15-bit texture, global: key and size, unscoped")
    check(after["entries"][:len(before["entries"])] == before["entries"] and new.startswith(text[:text.rfind("}\n  ]")]),
          "the catalog's entries and layout are kept")
    check(all(e["review"] == "new" and e["where"] for e in added), "added entries are review new, with where")
    again, added2, skipped2 = ma.apply(review, new)
    check(again == new and not added2 and skipped2 == 4, "a second apply adds nothing")
    # material_catalog_test's rules on the result.
    with tempfile.TemporaryDirectory() as tmp:
        (pathlib.Path(tmp) / "pc/assets/materials").mkdir(parents=True)
        (pathlib.Path(tmp) / "pc/tools").mkdir(parents=True)
        (pathlib.Path(tmp) / "pc/tests").mkdir(parents=True)
        (pathlib.Path(tmp) / "pc/assets/materials/catalog.json").write_text(new)
        for d in ("pc/assets/materials",):
            for f in (ROOT / d).iterdir():
                if f.is_dir():
                    shutil.copytree(f, pathlib.Path(tmp) / d / f.name)
        shutil.copy(ROOT / "pc/tools/check_material_maps.py", pathlib.Path(tmp) / "pc/tools")
        shutil.copy(ROOT / "pc/tests/material_catalog_test.py", pathlib.Path(tmp) / "pc/tests")
        import subprocess
        r = subprocess.run([sys.executable, str(pathlib.Path(tmp) / "pc/tests/material_catalog_test.py")],
                           capture_output=True, text=True)
        check(r.returncode == 0, f"material_catalog_test passes on the applied catalog ({r.stdout[-200:]}"
                                 f"{r.stderr[-400:]})")
    try:
        ma.apply({"kind": "material_rollout_review", "decisions": [dict(review["decisions"][0], preset="velvet")]},
                 text)
        check(False, "an unknown preset is refused")
    except ValueError as e:
        check("velvet" in str(e), f"an unknown preset is refused ({e})")
    try:
        ma.apply({"kind": "other"}, text)
        check(False, "a file that is not a review is refused")
    except ValueError:
        check(True, "a file that is not a review is refused")

    print(f"{'FAILED' if failures else 'passed'}: {len(failures)} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
