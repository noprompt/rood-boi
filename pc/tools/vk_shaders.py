#!/usr/bin/env python3
"""Build the vendored glslang (pc/third_party/glslang, BSD-3/Apache-2.0/MIT,
see its LICENSE.txt) and compile the Vulkan renderer's shaders
(pc/shaders/vulkan) to SPIR-V, embedded in a generated C header.

    python3 pc/tools/vk_shaders.py [--out pc/build/boot64/vk_shaders.h]

Each pc/shaders/vulkan/<name>.<stage> becomes `vk_spv_<name>_<stage>[]`
(uint32_t words) with its size in `vk_spv_<name>_<stage>_size` (bytes).
Shaders are only recompiled when a source (or an included .glsl) changed.
"""
import argparse
import hashlib
import os
import pathlib
import shutil
import struct
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
import shared_cache  # noqa: E402
from build_cache import tool_identity  # noqa: E402

SOURCE = ROOT / "pc/third_party/glslang"
SHADERS = ROOT / "pc/shaders/vulkan"
# Vendored shader sources the shaders include (SMAA, MIT: pc/third_party/smaa).
INCLUDE_DIRS = [ROOT / "pc/third_party/smaa"]
STAGES = ("vert", "geom", "frag", "comp")
# A Windows host (the native Windows builder, MSYS2) builds glslang.exe.
EXE = ".exe" if os.name == "nt" else ""


OPTIONS = ["-DCMAKE_BUILD_TYPE=Release", "-DENABLE_OPT=OFF", "-DGLSLANG_TESTS=OFF", "-DBUILD_TESTING=OFF",
           "-DGLSLANG_ENABLE_INSTALL=OFF", "-DENABLE_GLSLANG_BINARIES=ON", "-DBUILD_SHARED_LIBS=OFF",
           "-DBUILD_EXTERNAL=OFF"]


# The generated header's layout: a change regenerates it (the tag).
FORMAT = "2"


def glslang_key():
    """What the glslang build depends on: the source, the options, the
    compilers and CMake."""
    return {"source": shared_cache.tree_key(SOURCE), "options": OPTIONS,
            "env": {k: os.environ.get(k) for k in ("CC", "CXX", "CFLAGS", "CXXFLAGS")},
            "tools": tool_identity(["cc", "c++", "gcc", "g++", "cmake", "ninja"])}


def glslang(key):
    """The glslang standalone compiler, built once per machine from the
    vendored source into the shared build cache (pc/tools/shared_cache.py:
    third-party/glslang-<key>). Only the binary is kept."""
    def build(tmp):
        print(f"glslang: building into {tmp.parent}", flush=True)
        work = tmp / "work"
        generator = ["-G", "Ninja"] if shutil.which("ninja") else []
        subprocess.run(["cmake", "-S", str(SOURCE), "-B", str(work), *generator, *OPTIONS],
                       check=True, stdout=subprocess.DEVNULL)
        subprocess.run(["cmake", "--build", str(work), "--target", "glslang-standalone", "--parallel",
                        str(min(os.cpu_count() or 4, 8))], check=True, stdout=subprocess.DEVNULL)
        (tmp / "bin").mkdir()
        shutil.copy2(work / f"StandAlone/glslang{EXE}", tmp / f"bin/glslang{EXE}")
        shutil.rmtree(work)

    return shared_cache.entry("glslang", key, build) / f"bin/glslang{EXE}"


# The libraries the game links for shader hot reload (pc/src/shader_compiler.cpp),
# in link order. Their headers are the vendored source's (-I pc/third_party/glslang).
LIBRARIES = ["glslang/libglslang.a", "glslang/libglslang-default-resource-limits.a"]


def glslang_libraries(key, target="linux", compilers=None):
    """glslang's static libraries for linking into the game, built once per
    machine with the standalone's OPTIONS into the shared build cache
    (third-party/glslang-lib-<target>-<key>). Position independent: the
    engine library (build_boot.py --engine-library) links them too.
    target "windows" cross-compiles with MinGW-w64 (compilers: its gcc, g++)."""
    options = [*OPTIONS, "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"]
    if target == "windows":
        gcc, gxx = compilers
        options += ["-DCMAKE_SYSTEM_NAME=Windows", f"-DCMAKE_C_COMPILER={gcc}", f"-DCMAKE_CXX_COMPILER={gxx}"]
    entry_key = {**key, "target": target, "options": options}

    def build(tmp):
        print(f"glslang libraries ({target}): building into {tmp.parent}", flush=True)
        work = tmp / "work"
        generator = ["-G", "Ninja"] if shutil.which("ninja") else []
        subprocess.run(["cmake", "-S", str(SOURCE), "-B", str(work), *generator, *options],
                       check=True, stdout=subprocess.DEVNULL)
        subprocess.run(["cmake", "--build", str(work), "--target", "glslang", "glslang-default-resource-limits",
                        "--parallel", str(min(os.cpu_count() or 4, 8))], check=True, stdout=subprocess.DEVNULL)
        for library in LIBRARIES:
            (tmp / library).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(work / library, tmp / library)
        shutil.rmtree(work)

    entry = shared_cache.entry(f"glslang-lib-{target}", entry_key, build)
    return [entry / library for library in LIBRARIES]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default=str(ROOT / "pc/build/boot64/vk_shaders.h"))
    args = parser.parse_args()
    out = pathlib.Path(args.out)
    sources = sorted(p for p in SHADERS.iterdir() if p.suffix[1:] in STAGES)
    includes = sorted(SHADERS.glob("*.glsl")) + sorted(p for d in INCLUDE_DIRS for p in d.glob("*.hlsl"))
    digest = hashlib.sha256()
    for path in sources + includes:
        digest.update(path.name.encode() + b"\0" + path.read_bytes())
    # A different glslang (source, compiler) compiles them again.
    key = glslang_key()
    tag = "// sources " + digest.hexdigest() + " glslang " + shared_cache.digest(key) + " format " + FORMAT
    # The digest alone, for the persistent pipeline cache (vk_core.c): a
    # shader change starts it afresh. Rewritten only when it changes.
    digest_header = out.parent / "vk_shaders_digest.h"
    digest_text = ("/* Generated by pc/tools/vk_shaders.py: the digest of pc/shaders/vulkan. */\n"
                   f'#define VK_SHADERS_DIGEST "{digest.hexdigest()}"\n')
    if not digest_header.exists() or digest_header.read_text() != digest_text:
        digest_header.write_text(digest_text)
    if out.exists() and out.read_text().startswith(tag):
        return 0
    compiler = glslang(key)
    spv_dir = out.parent / "vk_spv"
    spv_dir.mkdir(parents=True, exist_ok=True)
    lines = [tag, "/* Generated by pc/tools/vk_shaders.py from pc/shaders/vulkan; do not edit. */", "#include <stddef.h>",
             "#include <stdint.h>", "#ifdef __cplusplus", 'extern "C" {', "#endif",
             "/* Defined once, where VK_SHADERS_DEFINE is (vk_shader_lookup.c, with the table by name). */",
             "#ifdef VK_SHADERS_DEFINE", "#define VK_SPV const uint32_t", "#else", "#define VK_SPV extern const uint32_t",
             "#endif"]
    names = []
    failed = False
    for path in sources:
        name = f"{path.stem}_{path.suffix[1:]}"
        spv = spv_dir / (name + ".spv")
        result = subprocess.run([str(compiler), "-V", "--target-env", "vulkan1.3", "-I" + str(SHADERS),
                                 *("-I" + str(d) for d in INCLUDE_DIRS), str(path),
                                 "-o", str(spv)], capture_output=True, text=True)
        if result.returncode:
            sys.stderr.write(result.stdout + result.stderr)
            failed = True
            continue
        data = spv.read_bytes()
        words = struct.unpack(f"<{len(data) // 4}I", data)
        body = ",\n".join(",".join(f"0x{w:08x}" for w in words[i:i + 8]) for i in range(0, len(words), 8))
        lines.append(f"VK_SPV vk_spv_{name}[]")
        lines.append("#ifdef VK_SHADERS_DEFINE")
        lines.append(f"= {{\n{body}\n}}")
        lines.append("#endif")
        lines.append(";")
        lines.append(f"#define vk_spv_{name}_size {len(data)}")
        names.append(name)
    if failed:
        return 1
    # Every stage by name (shader hot reload: what a stage's code is when nothing overrides it).
    lines += ["typedef struct {", "    const char* name;", "    const uint32_t* code;", "    size_t bytes;",
              "} vk_spv_entry;", f"#define VK_SPV_COUNT {len(names)}",
              "#ifdef VK_SHADERS_DEFINE", "const vk_spv_entry vk_spv_table[VK_SPV_COUNT] = {",
              *[f'    {{ "{n}", vk_spv_{n}, vk_spv_{n}_size }},' for n in names], "};", "#endif",
              "#undef VK_SPV", "#ifdef __cplusplus", "}", "#endif"]
    tmp = out.with_suffix(".tmp")
    tmp.write_text("\n".join(lines) + "\n")
    os.replace(tmp, out)
    print(f"Compiled {len(sources)} Vulkan shaders into {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
