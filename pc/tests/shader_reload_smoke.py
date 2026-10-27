#!/usr/bin/env python3
"""Shader hot reload (Vulkan; pc/docs/Vulkan_Renderer.md "Hot reload", RPC
shaders), on a copy of pc/shaders/vulkan as ROOD_SHADERS, in the save room:

    python3 pc/tests/shader_reload_smoke.py [--card pc/build/test-card1.mcd] [--out DIR]

- an edit: scaled.frag writing constant magenta shows within 3 s (the
  generation goes up, the window's centre is magenta); the time from the
  save to the picture is printed;
- an include: a comment added to material.glsl recompiles the stages that
  read it (hw.frag, native.frag through native_frag.glsl), and only them;
- a broken stage: errors[0] names scaled.frag and the line, the generation
  stays, the picture stays magenta (the last good shader);
- restored: the errors clear and the frame is the first one, byte for byte
  (the override dropped: the SPIR-V is the build's again);
- a save in two writes 100 ms apart: one apply, of the complete file;
- saves in quick succession (one broken among them): the newest applies, once;
- five reloads in a row: the live pipelines and shader modules are as many
  as after the first (nothing leaks), then reset gives the built-in shaders;
  a reset right after a save (its compile pending or running) sticks;
- a stage declaring a binding its pipeline's layout lacks: refused with the
  reason in errors, nothing applied, the frame unchanged;
- ROOD_SHADERS at an empty folder: the service is off, nothing reloads.
"""
import argparse
import os
import pathlib
import shutil
import sys
import time

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
sys.path.insert(0, str(ROOT / "pc/tests"))
from rood_rpc import OUT  # noqa: E402
from checkpoints import launch_at  # noqa: E402

# A constant colour from the start of main (the lit path returns before main's last line).
MAIN = "void main() {\n"


def frame(game, path):
    game.call("redraw")
    game.wait_presents(6)
    game.present_screenshot(str(path))
    return np.asarray(Image.open(path).convert("RGB")).astype(np.int32)


def centre(image):
    h, w, _ = image.shape
    return [int(v) for v in image[h // 2, w // 2]]


def status(game):
    return game.call("shaders")


def wait_generation(game, above, timeout):
    """The status once the generation passes `above` (None: timed out)."""
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        s = status(game)
        if s["generation"] > above:
            return s
        time.sleep(0.02)
    return None


def settle(game, seconds):
    """Polls for `seconds`; the last status (nothing pending any more)."""
    end = time.monotonic() + seconds
    s = status(game)
    while time.monotonic() < end or s["pending"]:
        time.sleep(0.05)
        s = status(game)
        if time.monotonic() > end + 10:
            break
    return s


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--card", default=os.environ.get("ROOD_TEST_CARD") or str(ROOT / "pc/build/test-card1.mcd"))
    parser.add_argument("--out", help="keep the frames and logs here")
    args = parser.parse_args()
    if os.environ.get("ROOD_RENDERER") != "vulkan":
        print("SKIP: shader hot reload is the Vulkan renderer's (ROOD_RENDERER=vulkan)")
        return 77
    if not pathlib.Path(args.card).exists():
        print("SKIP: no memory card", args.card)
        return 77
    out = pathlib.Path(args.out) if args.out else OUT / "shader_reload"
    out.mkdir(parents=True, exist_ok=True)
    card = out / "card1.mcd"
    shutil.copyfile(args.card, card)
    shaders = out / "shaders"
    shutil.rmtree(shaders, ignore_errors=True)
    shutil.copytree(ROOT / "pc/shaders/vulkan", shaders)
    scaled = shaders / "scaled.frag"
    original = scaled.read_text()
    assert original.count(MAIN) == 1, "scaled.frag's main() not found"
    (out / "lights").mkdir(exist_ok=True)
    (out / "settings.cfg").write_text("light_animation 0\ndust 0\naa off\nshader_reload_poll_ms 200\n")
    env = {"ROOD_LIGHTS": str(out / "lights"), "ROOD_LIGHTING": str(ROOT / "lighting"), "ROOD_SCALE": "2",
           "ROOD_WINDOW": "1280x960", "ROOD_SETTINGS": str(out / "settings.cfg"), "ROOD_SHADERS": str(shaders)}
    os.environ.pop("ROOD_SETTINGS", None)
    socket = os.environ.get("ROOD_RPC") or f"/tmp/rood-shader-smoke-{os.getpid()}.sock"
    failures = []

    def check(ok, message):
        print(("ok:   " if ok else "FAIL: ") + message, flush=True)
        if not ok:
            failures.append(message)

    def colour(rgb):
        return original.replace(MAIN, MAIN + f"    color = vec4({rgb}, 1.0);\n    return;\n")

    def save(path, text):
        tmp = path.with_suffix(path.suffix + ".tmp")
        tmp.write_text(text)
        os.replace(tmp, path)

    game = launch_at("save_room", card=card, fast=True, log=out / "game.log", extra_env=env, socket_path=socket)
    try:
        # A redrawn paused frame is the same every time (as material_smoke): no AO, no traced reflections.
        game.call("graphics", interpolate=False, lighting_preset="low")
        game.call("graphics", ao=0, reflection_bounces=0)
        game.run(20)
        s = settle(game, 1.0)
        check(s["on"] and s["scanned"] and s["dir"] == str(shaders) and not s["errors"] and not s["overridden"],
              f"on, watching the copy, every stage read once, nothing overridden ({s})")
        g0 = s["generation"]
        extra = s["pipelines"]["live"] - s["pipelines"]["recipes"]  # pipelines with no recipe (NRD's)
        first = frame(game, out / "first.png")
        print("first frame centre", centre(first))

        # An edit shows within 3 s.
        save(scaled, colour("1.0, 0.0, 1.0"))
        saved = time.monotonic()
        s = wait_generation(game, g0, 3.0)
        seen = None
        while s and time.monotonic() - saved < 3.0:
            game.wait_presents(1)
            game.present_screenshot(str(out / "magenta.png"))
            image = np.asarray(Image.open(out / "magenta.png").convert("RGB")).astype(np.int32)
            r, g, b = centre(image)
            if r > 200 and g < 60 and b > 200:
                seen = time.monotonic() - saved
                break
        check(s is not None and seen is not None,
              f"scaled.frag's magenta shows within 3 s (generation {s and s['generation']}, "
              f"{'%.0f ms save to visible' % (seen * 1000) if seen else 'not seen'}; compile and apply "
              f"{s and s['last_ms']} ms)")
        if seen:
            print(f"reload time: {seen * 1000:.0f} ms from the save to the picture")
        s = status(game)
        check(s["overridden"] == ["scaled_frag"] and s["last_stages"] == ["scaled_frag"],
              f"only scaled_frag compiled and overridden ({s['last_stages']}, {s['overridden']})")
        g1 = s["generation"]

        # An include: the stages that read it, directly or through another include.
        material = shaders / "material.glsl"
        save(material, material.read_text() + "// hot reload smoke: a comment\n")
        s = wait_generation(game, g1, 5.0)
        stages = set(s["last_stages"]) if s else set()
        check(s is not None and {"hw_frag", "native_frag", "native_ms_frag"} <= stages
              and "scaled_frag" not in stages and "fullscreen_vert" not in stages,
              f"material.glsl recompiled the stages that read it ({sorted(stages)})")
        check(s is not None and s["overridden"] == ["scaled_frag"],
              f"a comment changes no SPIR-V: nothing new overridden ({s and s['overridden']})")
        g2 = s["generation"] if s else g1

        # Broken: the last good shader stays.
        lines = colour("1.0, 0.0, 1.0").splitlines(True)
        lines.insert(9, "this is not glsl;\n")  # line 10
        save(scaled, "".join(lines))
        end = time.monotonic() + 5
        while time.monotonic() < end and not status(game)["errors"]:
            time.sleep(0.05)
        s = settle(game, 0.5)
        e = s["errors"][0] if s["errors"] else {}
        check(e.get("file", "").endswith("scaled.frag") and e.get("line") == 10 and s["generation"] == g2,
              f"the error names scaled.frag line 10, the generation stays ({e}, {s['generation']})")
        broken = frame(game, out / "broken.png")
        r, g, b = centre(broken)
        check(r > 200 and g < 60 and b > 200, f"the picture keeps the last good shader (centre {centre(broken)})")

        # Restored: the first frame again, byte for byte.
        save(scaled, original)
        s = wait_generation(game, g2, 5.0)
        check(s is not None and not s["errors"] and s["overridden"] == [],
              f"restored: the errors clear and nothing is overridden ({s and (s['errors'], s['overridden'])})")
        g3 = s["generation"] if s else g2
        restored = frame(game, out / "restored.png")
        check(restored.shape == first.shape and (restored == first).all(),
              f"the frame is the first one byte for byte ({int((restored != first).any(2).sum())} pixels differ)")

        # A save in two writes 100 ms apart: one apply, of the whole file.
        cyan = colour("0.0, 1.0, 1.0")
        half = len(cyan) // 2
        scaled.write_text(cyan[:half])
        time.sleep(0.1)
        scaled.write_text(cyan)
        s = wait_generation(game, g3, 5.0)
        s = settle(game, 1.0)
        image = frame(game, out / "cyan.png")
        r, g, b = centre(image)
        check(s["generation"] == g3 + 1 and not s["errors"] and r < 60 and g > 200 and b > 200,
              f"two writes: one apply ({s['generation'] - g3}), no errors, cyan ({centre(image)})")

        # Saves in quick succession (magenta, broken, magenta, then yellow): the newest wins, alone.
        g4 = status(game)["generation"]
        bad = colour("1.0, 0.0, 1.0").replace(MAIN, "this is not glsl;\n" + MAIN)
        for text in (colour("1.0, 0.0, 1.0"), bad, colour("1.0, 0.0, 1.0"), colour("1.0, 1.0, 0.0")):
            save(scaled, text)
            time.sleep(0.05)
        wait_generation(game, g4, 5.0)
        s = settle(game, 1.0)
        image = frame(game, out / "yellow.png")
        r, g, b = centre(image)
        check(s["generation"] == g4 + 1 and not s["errors"] and r > 200 and g > 200 and b < 60,
              f"quick saves: the newest applied, once ({s['generation'] - g4}), no errors, yellow ({centre(image)})")

        # Five reloads: nothing leaks.
        counts = []
        for i in range(5):
            g = status(game)["generation"]
            save(scaled, colour("1.0, 0.0, 1.0" if i % 2 == 0 else "0.0, 1.0, 1.0"))
            s = wait_generation(game, g, 5.0)
            if not s:
                break
            frame(game, out / f"reload{i}.png")
            p = status(game)["pipelines"]
            counts.append((p["live"], p["live_modules"], p["replaced"], p["recipes"]))
        check(len(counts) == 5 and len(set(counts)) == 1,
              f"5 reloads: live pipelines, modules, replaced, recipes unchanged {counts}")
        game.call("shaders", action="reset")  # applied between frames
        image = frame(game, out / "reset.png")
        s = status(game)
        check(s["overridden"] == [] and (image == first).all(),
              f"reset: the built-in shaders, the first frame ({int((image != first).any(2).sum())} pixels differ)")
        p = status(game)["pipelines"]
        check(p["replaced"] == 0 and p["live"] == p["recipes"] + extra,
              f"reset: the original pipelines, nothing replaced, none left over ({p})")

        # A reset right after a save (its compile pending or running): it sticks.
        save(scaled, colour("1.0, 0.0, 1.0"))
        time.sleep(0.25)
        game.call("shaders", action="reset")
        time.sleep(2.0)
        s = settle(game, 0.5)
        image = frame(game, out / "reset-sticks.png")
        check(s["overridden"] == [] and (image == first).all(),
              f"a reset during a pending compile sticks ({s['overridden']}, "
              f"{int((image != first).any(2).sum())} pixels differ)")

        # A stage that needs more than its pipeline's layout: refused, the last good code stays.
        g5 = status(game)["generation"]
        save(scaled, original.replace(MAIN, "layout(binding = 30) uniform sampler2D extra_tex;\n" + MAIN
                                      + "    color = texture(extra_tex, uv);\n    return;\n"))
        end = time.monotonic() + 5
        while time.monotonic() < end and not status(game)["errors"]:
            time.sleep(0.05)
        s = settle(game, 0.5)
        e = s["errors"][0] if s["errors"] else {}
        image = frame(game, out / "layout.png")
        # The error banner is the only change: a band at the bottom of the window.
        rows = np.nonzero((image != first).any(2).any(1))[0]
        banner = len(rows) > 0 and rows.min() >= image.shape[0] * 0.85
        check("binding 30" in e.get("message", "") and s["generation"] == g5 and s["overridden"] == [] and banner,
              f"an added binding is refused, nothing applied, the picture as it was but the error banner at the "
              f"bottom ({e.get('message')}, {s['generation'] - g5}, rows {rows.min() if len(rows) else None}.."
              f"{rows.max() if len(rows) else None} differ)")
        save(scaled, original)
        end = time.monotonic() + 5
        while time.monotonic() < end and status(game)["errors"]:
            time.sleep(0.05)
        check(not status(game)["errors"], "restored: the layout error clears")
    finally:
        game.close()

    # No sources: off, and nothing changes.
    empty = out / "empty"
    shutil.rmtree(empty, ignore_errors=True)
    empty.mkdir()
    env["ROOD_SHADERS"] = str(empty)
    game = launch_at("save_room", card=card, fast=True, log=out / "game-empty.log", extra_env=env, socket_path=socket)
    try:
        game.run(30)
        s = status(game)
        check(not s["on"] and s["generation"] == 0 and s["pipelines"]["recipes"] == 0,
              f"no stage files: off, no recipes kept ({s})")
    finally:
        game.close()
    print(f"passed: {len(failures)} failure(s)" if not failures else f"FAILED: {len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
