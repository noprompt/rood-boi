#!/usr/bin/env python3
"""The grouped model builders' alternate-palette records (native_model's pc_nm_view_polygons, actor_native.c).

    python3 pc/tests/grouped_mesh_smoke.py [--card CARD] [--out DIR]

A model drawn by the grouped builders takes the alternate CLUT (the CLUT + 0x480) for the polygons of the material groups whose bit is set in its mask (the palette pulse's
byte at +0x64 of the object). In the fight room with the weapon drawn, the mask of Ashley's models is written (RPC field store) and what the renderer is given is dumped
(RPC material model_dump: each polygon's page and CLUT as drawn):
  - mask 0: every model draws with one CLUT;
  - mask 0x55 and 0x0F: a model has both CLUTs, the alternate being the first + 0x480;
  - mask 0xFF: a model whose every polygon takes the alternate.
Parity with the build before the shared reader (the same dumps, byte for byte, in the parent build) was checked by hand when it was written; this keeps the behaviour."""
import argparse
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
sys.path.insert(0, str(ROOT / "pc/tests"))
import rood_rpc  # noqa: E402
from checkpoints import launch_at  # noqa: E402

ROOM = (48, 10)
MASKS = ("vs_battle_wepModels[0]->unk64", "vs_battle_wepModels[1]->unk64", "vs_actors_actorRecords[0]->unk0.palettePulse.unk0")


def cluts(path):
    return sorted(set(re.findall(r"clut ([0-9a-f]{4})", pathlib.Path(path).read_text())))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--card", default=str(ROOT / "pc/build/test-card1.mcd"))
    parser.add_argument("--out", default=str(rood_rpc.OUT / "grouped_mesh_smoke"))
    args = parser.parse_args()
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    (out / "settings.cfg").write_text("qol_skip_charging 0\nui_menus 0\nshader_reload 0\n")
    failures = []

    def check(ok, message):
        print(("ok:   " if ok else "FAIL: ") + message, flush=True)
        if not ok:
            failures.append(message)

    g = launch_at("save_room", card=args.card, fast=True, log=out / "game.log",
                  extra_env={"ROOD_GI": "0", "ROOD_INTERPOLATE": "0", "ROOD_SETTINGS": str(out / "settings.cfg"), "ROOD_AUDIO": "none"})
    try:
        g.call("room_goto", hold=True, zone=ROOM[0], room=ROOM[1], enemies=True, scripts=False)
        for _ in range(80):
            g.run(20)
            if g.call("room_goto", action="status")["phase"] in (0, 4):
                break
        g.pause()
        g.press("circle", vsyncs=3, settle=90)  # the weapon drawn
        g.run(60)
        seen = {}
        for mask in (0, 0x55, 0x0F, 0xFF):
            for path in MASKS:
                g.store(path, mask)
            g.run(4)
            folder = out / f"mask_{mask:02x}"
            folder.mkdir(exist_ok=True)
            sets = []
            for row in g.call("material", action="model_ids")["models"]:
                path = folder / f"{row['legacy']}.txt"
                try:
                    g.call("material", action="model_dump", model=row["legacy"], path=str(path))
                except rood_rpc.RpcError:
                    continue  # (not drawn in this frame)
                sets.append(cluts(path))
            seen[mask] = sets
    finally:
        g.close()
    check(seen[0] and all(len(s) == 1 for s in seen[0]), f"mask 0: every model draws with one CLUT ({seen[0]})")
    for mask in (0x55, 0x0F):
        mixed = [s for s in seen[mask] if len(s) == 2 and int(s[1], 16) - int(s[0], 16) == 0x480]
        check(bool(mixed), f"mask {mask:#x}: a model has its own CLUT and the alternate (+0x480): {mixed[:1]}")
    base = {s[0] for s in seen[0]}
    whole = [s for s in seen[0xFF] if len(s) == 1 and f"{int(s[0], 16) - 0x480:04x}" in base]
    check(bool(whole), f"mask 0xFF: a model draws wholly with the alternate CLUT: {whole[:1]}")
    print("FAIL" if failures else "OK")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
