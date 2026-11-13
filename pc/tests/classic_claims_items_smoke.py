#!/usr/bin/env python3
"""Every claim command rood.classic draws is a draw item (pc/src/hud/hud_bridge.c emit_command).

    python3 pc/tests/classic_claims_items_smoke.py [--card pc/build/test-card1.mcd] [--binary PATH]

The routes build_compare plays (the menus and screens whose HUD rood.classic claims) are run in a game of their
own each with ROOD_CLASSIC_ITEMS=1, which logs, once for each command type, whether the claim's output was taken as
draw items or left as the game's packets ("[classic] command type N: items|packets", classic_parity.c). The test fails
when any command type but PACKET (the game's own words) is left as packets (the decoder refusing a claim's words, or a printer writing raw GP0 words)
and when too few types were seen at all (the routes drew nothing: the check would pass for nothing)."""
import argparse
import os
import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
ROUTES = ["dialogue", "items", "areamap", "map", "platforms", "status", "storage"]
MIN_TYPES = 4  # (sprite, bar, text and a words-only command at least)
GAME_WORDS = {22}  # PACKET: the game's own raw words, given as they are (a lone draw mode stays a packet)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--card", default=str(ROOT / "pc/build/test-card1.mcd"))
    parser.add_argument("--binary", default=str(ROOT / "pc/build/boot64/rood_battle_probe"))
    args = parser.parse_args()
    items, packets = set(), {}
    for route in ROUTES:
        with tempfile.TemporaryDirectory(prefix="claims-items-", dir=ROOT / "pc/build") as out:
            subprocess.run([sys.executable, str(ROOT / "pc/tools/build_compare.py"), "--play-menus", args.binary, "--menus", route,
                            "--menu-sample", "20", "--claims", "on", "--aspect", "4:3", "--renderer", "vulkan", "--card", args.card,
                            "--out", out, "--env", "ROOD_CLASSIC_ITEMS=1"], capture_output=True, text=True,
                           env=dict(os.environ, BUILD_COMPARE_GI="0"))
            for log in pathlib.Path(out).rglob("*.log"):
                for number, kind in re.findall(r"\[classic\] command type (\d+): (items|packets)", log.read_text(errors="ignore")):
                    if kind == "items":
                        items.add(int(number))
                    else:
                        packets.setdefault(int(number), set()).add(route)
    print(f"command types taken as items: {sorted(items)}")
    ok = True
    packets = {t: r for t, r in packets.items() if t not in GAME_WORDS}
    if packets:
        ok = False
        print(f"FAIL: command types left as packets: { {t: sorted(r) for t, r in packets.items()} }")
    if len(items) < MIN_TYPES:
        ok = False
        print(f"FAIL: only {len(items)} command types seen as items (at least {MIN_TYPES}): the routes drew too little")
    print("ok" if ok else "FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
