#!/usr/bin/env python3
"""Apply a material rollout review (the JSON review.html exports:
pc/tools/material_rollout.py) to a material catalog.

    python3 pc/tools/material_rollout_apply.py REVIEW.json [--catalog pc/assets/materials/catalog.json]
                                               [--dry-run] [--out PATH]

Every accepted decision (with its preset, the proposed one or the one the
reviewer changed it to; "none" adds nothing) becomes catalog entries, review
"new", with fresh ids (M###, after the catalog's highest):

- a palette, scope "rooms": one palette entry ({"match": {"clut"}}) per room
  it was surveyed in, scoped to that room (a palette can be reused elsewhere
  for other art, so the catalog keeps palette entries scoped: a "global"
  palette decision is applied per room too);
- a texture (15-bit, no palette): its key and size, per room, or one
  unscoped entry for scope "global".

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


def ident(entry):
    """What an entry matches, and where: duplicates share it."""
    m = entry.get("match", {})
    scope = entry.get("scope", {}).get("room")
    return (m.get("key", ""), tuple(m.get("size", [])), m.get("clut", ""), tuple(scope) if scope else None)


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
        for zone, room in rooms:
            label = names.get(f"{zone}-{room}", "")
            where = f"zone {zone} room {room}" + (f" ({label})" if label else "") + f"; {base}"
            out.append({"name": name, "where": where, "match": dict(match), "scope": {"room": [zone, room]},
                        "preset": preset, "review": "new"})
    return out


def render(entry):
    """One entry in the catalog's own layout."""
    head = ", ".join(f"{json.dumps(k)}: {json.dumps(entry[k])}" for k in ("id", "name", "where"))
    match = json.dumps(entry["match"], separators=(", ", ": ")).replace("{", "{ ").replace("}", " }")
    tail = []
    if "scope" in entry:
        tail.append('"scope": { "room": ' + json.dumps(entry["scope"]["room"], separators=(", ", ": ")) + " }")
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
            z, r = e["scope"]["room"]
            assert 0 <= z <= 255 and 0 <= r <= 255, e["id"]


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
