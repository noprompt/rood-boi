#!/usr/bin/env python3
"""The in-process shader compiler (pc/src/shader_compiler.cpp) against the
build's: compiles the shaders with the standalone glslang as the build does
(pc/tools/vk_shaders.py, into this test's folder), links
pc/tests/shader_compiler_probe.cpp with glslang's libraries and runs it.

    python3 pc/tests/shader_compiler_test.py [--out DIR]
"""
import argparse
import os
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
import vk_shaders  # noqa: E402


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default=os.environ.get("ROOD_OUT") or str(ROOT / "pc/build/tests/shader_compiler"))
    args = parser.parse_args()
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    # The build's SPIR-V, from the standalone compiler.
    subprocess.run([sys.executable, str(ROOT / "pc/tools/vk_shaders.py"), "--out", str(out / "vk_shaders.h")],
                   check=True)
    libraries = vk_shaders.glslang_libraries(vk_shaders.glslang_key())
    probe = out / "shader_compiler_probe"
    lookup = out / "vk_shader_lookup.o"
    subprocess.run(["gcc", "-std=gnu11", "-O1", "-Wall", "-Wextra", "-Werror", "-I" + str(out), "-c",
                    str(ROOT / "pc/src/vk_shader_lookup.c"), "-o", str(lookup)], check=True)
    subprocess.run(["g++", "-std=c++17", "-O1", "-Wall", "-Wextra", "-Werror", "-I" + str(ROOT / "pc/src"),
                    "-I" + str(vk_shaders.SOURCE), str(ROOT / "pc/tests/shader_compiler_probe.cpp"),
                    str(ROOT / "pc/src/shader_compiler.cpp"), str(lookup), *map(str, libraries), "-lpthread", "-o", str(probe)],
                   check=True)
    scratch = out / "scratch"
    shutil.rmtree(scratch, ignore_errors=True)
    scratch.mkdir()
    # From the repository root: the SMAA include folder is pc/third_party/smaa, as in the game.
    shaders = scratch / "shaders"  # the probe writes changed stages beside their includes
    shutil.copytree(vk_shaders.SHADERS, shaders)
    return subprocess.run([str(probe), str(shaders), str(out / "vk_spv"), str(scratch)],
                          cwd=ROOT).returncode


if __name__ == "__main__":
    sys.exit(main())
