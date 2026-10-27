#!/usr/bin/env python3
"""The sky's light from the game's own sky (pc/src/environment.cpp `game_sky`;
pc/docs/Vulkan_Renderer.md "The game's sky"), on whichever renderer the run
uses (OpenGL, Vulkan).

    python3 pc/tests/game_sky_smoke.py [--card pc/save/card1.mcd] [--shots DIR]

Continues a copy of the card's save (zone 9 room 17, the wine cellar's save
room: roofed) with private copies of the lighting packs and an empty user
layer, at the Ultra preset, then:

- roofed room: no `env sky`, the renderers' record is all zeros whatever the
  game draws behind it, and the picture with the environment on and off is
  the same;
- Rue Vermillion (zone 32 room 0, open): the game's background sphere is
  captured (kind sphere, its zenith a light blue, brighter than the
  horizon), the sky uses it (`source` game by default) and the record is
  its colours x game_scale x intensity; `source=manual` gives the manual
  colours, `game_scale` scales the record, and either edit saves to the
  user layer as one override line; the indirect light view with the game's
  sky and with the manual one (numbers printed: before / after);
- a room whose game sky is black (the save room, given a sky by RPC; the
  game draws no sky in 21 of the 82 rooms open to the sky, which have no
  door to warp to): the manual colours, the record as before this change;
- Snowfly Forest (zone 40 room 0): the flat backdrop's colour (a grey);
- no crash, shader error or (Vulkan, with the Khronos layer on
  VK_LAYER_PATH) validation message.

Frame-based waits only (RPC step counts).
"""
import argparse
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
from editor_cutaway_smoke import default_card  # noqa: E402
import lighting_format as lf  # noqa: E402

ROOFED = (9, 17)  # the save room
TOWN = (32, 0)  # Rue Vermillion: the sphere, light blue above, black below the horizon
FOREST = (40, 0)  # Snowfly Forest: the flat backdrop


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--card", default=str(default_card()))
    ap.add_argument("--shots", help="keep the screenshots here")
    args = ap.parse_args()
    if not pathlib.Path(args.card).exists():
        print("SKIP: no memory card", args.card)
        return 77
    for room in (TOWN, FOREST):
        gen = ROOT / "lighting/default/generated" / lf.room_file_name(*room)
        if not gen.exists() or "env sky" not in gen.read_text():
            print(f"SKIP: no generated sky for zone {room[0]} room {room[1]} (pc/tools/generate_lighting.py)")
            return 77
    out = OUT / "game_sky_smoke"
    shutil.rmtree(out, ignore_errors=True)
    out.mkdir(parents=True)
    shots = pathlib.Path(args.shots) if args.shots else out
    shots.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(args.card, out / "card1.mcd")
    packs, user = out / "packs", out / "user"
    shutil.copytree(ROOT / "lighting", packs)
    user.mkdir()
    vulkan = os.environ.get("ROOD_RENDERER") == "vulkan"
    env = {"ROOD_LIGHTS": str(user), "ROOD_LIGHTING": str(packs), "ROOD_GI": "1", "ROOD_SCALE": "2",
           "ROOD_LIGHTING_PRESET": "ultra"}
    if vulkan and os.environ.get("VK_LAYER_PATH"):
        env.setdefault("ROOD_VK_VALIDATE", "1")
    os.environ.pop("ROOD_SETTINGS", None)
    socket = os.environ.get("ROOD_RPC") or f"/tmp/rood-gsky-{os.getpid()}.sock"
    failures = []

    def check(ok, message):
        print(("ok:   " if ok else "FAIL: ") + message, flush=True)
        if not ok:
            failures.append(message)
        return ok

    game = launch_at("save_room", card=out / "card1.mcd", fast=True, log=out / "game.log", extra_env=env,
                     socket_path=socket)

    def warp(zone, room):
        game.call("room_goto", zone=zone, room=room)
        for _ in range(90):
            game.run(20)
            if game.call("room_goto", action="status")["phase"] in (0, 4):
                break
        game.run(60)
        st = game.state()
        return check((st["zone"], st["room"]) == (zone, room), f"warped to zone {zone} room {room}")

    def shot(name, frames=90):
        game.run(frames)
        path = game.present_screenshot(shots / f"game-sky-{name}.png")
        return np.asarray(Image.open(path).convert("RGB"), np.float32)

    def lum(image):
        return image @ np.array([0.299, 0.587, 0.114], np.float32)

    def view_mean(image):
        h = image.shape[0]
        return float(lum(image)[int(h * 0.12):int(h * 0.78)].mean())

    def close(a, b, tol=2e-3):
        return all(abs(x - y) <= tol for x, y in zip(a, b))

    def expected(colours, scale, intensity):
        return [max(c, 0.0) * scale * intensity for c in colours]

    def user_lines(room):
        path = user / lf.room_file_name(*room)
        text = path.read_text() if path.exists() else ""
        return [line for line in text.splitlines() if line and not line.startswith(("#", "rood-lighting"))]

    try:
        st = game.state()
        if (st["zone"], st["room"]) != ROOFED and not warp(*ROOFED):
            return 1
        print(f"renderer {'vulkan' if vulkan else 'opengl'}, preset {game.call('graphics').get('lighting_preset')}",
              flush=True)

        # ---- roofed: unchanged ----
        e = game.call("environment")
        zeros = all(v == 0 for k in ("zenith", "horizon", "ground", "sun_col") for v in e["gpu"][k])
        check(not e["sky"]["defined"] and not e["active"] and zeros,
              f"the roofed save room has no sky: the record is zeros (game sky behind it: {e['sky']['game']['kind']})")
        on = shot("roofed-on")
        game.call("environment", **{"global": False})
        off = shot("roofed-off")
        game.call("environment", **{"global": True})
        diff = float(np.abs(on - off).mean())
        check(diff < 3.0, f"the roofed room looks the same with the environment on and off (mean difference {diff:.2f})")
        # A sky where the game draws none (all five rings black): the manual colours, as before.
        game.call("environment", sky={"zenith": [0.2, 0.25, 0.4], "horizon": [0.3, 0.3, 0.35],
                                      "ground": [0.05, 0.04, 0.03], "intensity": 1.5})
        e = game.call("environment")
        sky = e["sky"]
        check(sky["defined"] and sky["source"] == "game" and sky["game"]["kind"] == "none" and sky["using"] == "manual"
              and close(e["gpu"]["zenith"][:3], [0.3, 0.375, 0.6]) and close(e["gpu"]["ground"][:3], [0.075, 0.06, 0.045]),
              f"no game sky: source game falls back to the manual colours ({e['gpu']['zenith']}, {e['gpu']['ground']})")
        game.call("environment", remove="sky")
        e = game.call("environment")
        check(not e["active"] and all(v == 0 for v in e["gpu"]["zenith"]), "removed again: the record is zeros")

        # ---- Rue Vermillion: the sphere ----
        if warp(*TOWN):
            e = game.call("environment")
            sky, g = e["sky"], e["sky"]["game"]
            z, h = g["zenith"], g["horizon"]
            check(g["kind"] == "sphere" and sum(z) > 0.6,
                  f"the town's game sky is the sphere, its zenith lit ({g['kind']}, rings {g['rings']})")
            check(z[2] >= z[0] and sum(z) > sum(h) + 0.3,
                  f"plausible: a blue-leaning zenith brighter than the horizon (zenith {z}, horizon {h})")
            check(sky["source"] == "game" and sky["using"] == "game",
                  f"the sky takes the game's colours by default (source {sky['source']}, using {sky['using']})")
            want = [expected(g[k], sky["game_scale"], sky["intensity"]) for k in ("zenith", "horizon")]
            want.append(expected(sky["ground"], 1, sky["intensity"]))  # the ground is always the room's own
            got = [e["gpu"][k][:3] for k in ("zenith", "horizon", "ground")]
            check(all(close(a, b) for a, b in zip(want, got)) and e["gpu"]["zenith"][3] == 1,
                  f"the record is the game's colours x game_scale {sky['game_scale']} x intensity, the room's "
                  f"ground ({got})")
            game_hash = e["hash"]
            after_full = view_mean(shot("town-game", 150))
            game.call("graphics", gi_debug=1)  # the indirect light alone
            after = view_mean(shot("town-indirect-game", 150))
            game.call("environment", sky={"source": "manual"})
            m = game.call("environment")
            manual = [expected(m["sky"][k], 1, m["sky"]["intensity"]) for k in ("zenith", "horizon", "ground")]
            check(m["sky"]["using"] == "manual" and all(close(a, b[:3]) for a, b in zip(
                manual, [m["gpu"][k] for k in ("zenith", "horizon", "ground")])) and m["hash"] != game_hash,
                  f"source=manual: the manual colours, a new history hash ({m['gpu']['zenith']})")
            before = view_mean(shot("town-indirect-manual", 150))
            game.call("graphics", gi_debug=0)
            before_full = view_mean(shot("town-manual", 150))
            print(f"town: indirect light view mean {before:.2f} (manual, before) -> {after:.2f} (game sky); "
                  f"picture {before_full:.2f} -> {after_full:.2f}; record zenith {m['gpu']['zenith'][:3]} -> "
                  f"{got[0]}, horizon {m['gpu']['horizon'][:3]} -> {got[1]}", flush=True)
            check(after > 0.5, f"the game's sky lights the town (indirect view mean {after:.2f})")
            game.call("lighting", action="reload")
            game.run(4)
            game.call("environment", sky={"game_scale": 0.5})
            e2 = game.call("environment")
            check(close(e2["gpu"]["zenith"][:3], expected(g["zenith"], 0.5, sky["intensity"])),
                  f"game_scale 0.5 doubles the record ({e2['gpu']['zenith'][:3]})")
            saved = game.call("lighting", action="save")
            check(saved["ok"] and user_lines(TOWN) == ["override env:sky game_scale=0.5"],
                  f"saving writes one override line ({user_lines(TOWN)})")
            game.call("environment", sky={"game_scale": 0.25, "source": "manual"})
            game.call("lighting", action="save")
            check(user_lines(TOWN) == ["override env:sky source=manual"],
                  f"source=manual saves as one override line ({user_lines(TOWN)})")
            (user / lf.room_file_name(*TOWN)).unlink()
            game.call("lighting", action="reload")
            e3 = game.call("environment")
            check(e3["sky"]["source"] == "game" and e3["hash"] == game_hash,
                  "without the file: the game's sky again, the same record (hash)")

        # ---- Snowfly Forest: the flat backdrop ----
        if warp(*FOREST):
            e = game.call("environment")
            g = e["sky"]["game"]
            c = g["zenith"]
            check(g["kind"] == "flat" and 0.2 < sum(c) / 3 < 0.9 and max(c) - min(c) < 0.15
                  and g["horizon"] == c and g["ground"] == c,
                  f"the forest's backdrop: one grey everywhere ({g['kind']}, {c})")
            check(e["sky"]["using"] == "game", "the forest's sky takes it")
            shot("forest-game")
    finally:
        game.close()
    log = (out / "game.log").read_text(errors="replace")
    bad = [line for line in log.splitlines() if "validation:" in line or "[crash]" in line or "[gl] shader" in line]
    check(not bad, "no crash, shader error or validation message" + (f": {bad[:3]}" if bad else ""))
    print("PASS" if not failures else f"FAIL: {len(failures)} check(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
