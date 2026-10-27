#!/usr/bin/env python3
"""Apply a material rollout review (the JSON review.html exports:
pc/tools/material_rollout.py) to a material catalog.

    python3 pc/tools/material_rollout_apply.py REVIEW.json [--catalog pc/assets/materials/catalog.json]
                                               [--dry-run] [--out PATH]

Every accepted decision (with its preset, the proposed one or the one the
reviewer changed it to; "none" adds nothing) becomes catalog entries, review
"new", with fresh ids (M###, after the catalog's highest):

- a palette: ONE palette entry ({"match": {"clut"}}) scoped to the rooms it
  was surveyed in (scope {"rooms": [[zone, room], ...]}, or {"room": [zone,
  room]} for a single room). A palette can be reused elsewhere for other
  art, so the catalog keeps palette entries scoped: a "global" palette
  decision is scoped to its rooms too;
- a texture (15-bit, no palette): its key and size, scoped to its rooms the
  same way, or one unscoped entry for scope "global".

An entry that the catalog already has (the same match and scope) is
skipped, so applying a review twice adds nothing. The catalog keeps its
layout: the new entries are written one per line block at the end of
"entries". The result is parsed back and checked (ids, keys, presets)
before it is written; --dry-run prints what would be added.
"""
import argparse
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CATALOG = ROOT / "pc/assets/materials/catalog.json"
HEX10 = re.compile(r"^[0-9a-f]{10}$")


def scope_rooms(rooms):
    """The scope for a list of (zone, room): {"room"} for one, {"rooms"} for more."""
    rooms = [list(r) for r in rooms]
    return {"room": rooms[0]} if len(rooms) == 1 else {"rooms": rooms}


def rooms_of(entry):
    """The rooms an entry is scoped to (a frozenset of (zone, room)), or None (everywhere)."""
    scope = entry.get("scope")
    if not scope:
        return None
    if "room" in scope:
        return frozenset([tuple(scope["room"])])
    return frozenset(tuple(r) for r in scope["rooms"])


def ident(entry):
    """What an entry matches, and where: duplicates share it."""
    m = entry.get("match", {})
    return (m.get("key", ""), tuple(m.get("size", [])), m.get("clut", ""), rooms_of(entry))


def next_id(ids):
    n = max([int(i[1:]) for i in ids if re.fullmatch(r"M\d+", i)] + [0])
    while True:
        n += 1
        yield f"M{n:03d}"


def entries_for(decision, presets):
    """The catalog entries for one review decision (no ids yet)."""
    if decision.get("decision") != "accept":
        return []
    preset = decision.get("preset") or decision.get("proposed")
    if not preset or preset == "none":
        return []
    if preset not in presets:
        raise ValueError(f"{decision.get('id')}: unknown preset {preset!r}")
    kind = decision.get("kind", "palette")
    if kind == "palette":
        if not HEX10.match(decision.get("clut", "")):
            raise ValueError(f"{decision.get('id')}: bad palette key {decision.get('clut')!r}")
        match = {"clut": decision["clut"]}
        what = f"every texture with palette {decision['clut']}"
    else:
        size = decision.get("size") or []
        if not HEX10.match(decision.get("key", "")) or len(size) != 2 or not all(
                isinstance(n, int) and 1 <= n <= 256 for n in size):
            raise ValueError(f"{decision.get('id')}: bad texture {decision.get('key')!r} {size}")
        match = {"key": decision["key"], "size": list(size)}
        if decision.get("clut"):
            match["clut"] = decision["clut"]
        what = f"the texture {decision['key']} {size[0]}x{size[1]}"
    note = decision.get("note", "").strip()
    name = note or f"{preset.capitalize()} ({decision.get('id', 'rollout')})"
    changed = f"; reviewer chose {preset} over {decision['proposed']}" if decision.get("changed") and \
        decision.get("proposed") and decision["proposed"] != preset else ""
    base = f"material rollout {decision.get('id', '')}: {what}{changed}"
    rooms = [tuple(r) for r in decision.get("rooms", [])]
    names = decision.get("room_names", {})
    out = []
    if kind == "palette" and not rooms:
        raise ValueError(f"{decision.get('id')}: a palette entry needs the rooms it is scoped to")
    if kind != "palette" and (decision.get("scope") == "global" or not rooms):
        where = f"{base}; everywhere (surveyed in {len(rooms)} rooms, coverage {decision.get('coverage', 0):.2f})"
        out.append({"name": name, "where": where, "match": match, "preset": preset, "review": "new"})
    else:
        rooms = list(dict.fromkeys(rooms))
        labels = []
        for zone, room in rooms:
            label = names.get(f"{zone}-{room}", "")
            labels.append(f"{zone}/{room}" + (f" ({label})" if label else ""))
        where = ("zone %d room %d" % rooms[0] + (f" ({names[f'{rooms[0][0]}-{rooms[0][1]}']})"
                 if names.get(f"{rooms[0][0]}-{rooms[0][1]}") else "")) if len(rooms) == 1 else \
            f"{len(rooms)} rooms: " + ", ".join(labels)
        out.append({"name": name, "where": f"{where}; {base}", "match": dict(match), "scope": scope_rooms(rooms),
                    "preset": preset, "review": "new"})
    return out


def render(entry):
    """One entry in the catalog's own layout."""
    head = ", ".join(f"{json.dumps(k)}: {json.dumps(entry[k])}" for k in ("id", "name", "where"))
    match = json.dumps(entry["match"], separators=(", ", ": ")).replace("{", "{ ").replace("}", " }")
    tail = []
    if "scope" in entry:
        (field, value), = entry["scope"].items()
        tail.append('"scope": { ' + json.dumps(field) + ": " + json.dumps(value, separators=(", ", ": ")) + " }")
    tail += [f"{json.dumps(k)}: {json.dumps(entry[k])}" for k in ("preset", "review") if k in entry]
    return f"    {{\n      {head},\n      \"match\": {match},\n      {', '.join(tail)}\n    }}"


def apply(review, catalog_text):
    """(new catalog text, the entries added, the duplicates skipped)."""
    catalog = json.loads(catalog_text)
    if review.get("kind") != "material_rollout_review":
        raise ValueError("not a material rollout review (kind material_rollout_review)")
    presets = catalog.get("presets", {})
    have = {ident(e) for e in catalog.get("entries", [])}
    ids = next_id([e["id"] for e in catalog.get("entries", [])])
    added, skipped = [], 0
    for d in review.get("decisions", []):
        for e in entries_for(d, presets):
            k = ident(e)
            if k in have:
                skipped += 1
                continue
            have.add(k)
            added.append({"id": next(ids), **e})
    if not added:
        return catalog_text, added, skipped
    end = catalog_text.rfind("]")
    if end < 0 or '"entries"' not in catalog_text:
        raise ValueError("catalog without an entries list")
    body = catalog_text[:end].rstrip()
    sep = "" if body.endswith("[") else ","
    text = body + sep + "\n" + ",\n".join(render(e) for e in added) + "\n  " + catalog_text[end:]
    check(json.loads(text), len(catalog.get("entries", [])) + len(added))
    return text, added, skipped


def check(data, count):
    entries = data["entries"]
    assert len(entries) == count, "entry count"
    ids = [e["id"] for e in entries]
    assert len(ids) == len(set(ids)), "duplicate ids"
    for e in entries:
        m = e["match"]
        assert "key" in m or ("clut" in m and HEX10.match(m["clut"])), e["id"]
        if "key" in m:
            assert HEX10.match(m["key"]) and len(m["size"]) == 2, e["id"]
        if "preset" in e:
            assert e["preset"] in data["presets"], e["id"]
        if "scope" in e:
            rooms = rooms_of(e)
            assert rooms and all(0 <= z <= 255 and 0 <= r <= 255 for z, r in rooms), e["id"]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("review")
    parser.add_argument("--catalog", default=str(CATALOG))
    parser.add_argument("--out", help="write here instead of over --catalog")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)
    review = json.loads(pathlib.Path(args.review).read_text())
    path = pathlib.Path(args.catalog)
    text, added, skipped = apply(review, path.read_text())
    for e in added:
        print(f"  + {e['id']} {e['preset']:14} {json.dumps(e['match'])} {json.dumps(e.get('scope', 'everywhere'))}")
    print(f"{len(added)} entries added, {skipped} already in the catalog")
    if added and not args.dry_run:
        out = pathlib.Path(args.out) if args.out else path
        out.write_text(text)
        print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
