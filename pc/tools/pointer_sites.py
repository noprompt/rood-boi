#!/usr/bin/env python3
"""Every place that reaches a struct by byte offset, which a layout change breaks silently.

    python3 pc/tools/pointer_sites.py vs_main_HeapHeader        Zig sites on the struct, by name
    python3 pc/tools/pointer_sites.py raw                       Zig sites on byte, void and integer bases
    python3 pc/tools/pointer_sites.py --c vs_main_HeapHeader    C and Python sites worth a look (text scan)

The compiler does not catch `psx.byteAt(T, base, 0x34)`: it compiles for any base. So the Zig side rejects
chosen base types at compile time (game/common/psx.zig, `audit`, fed by game/common/psx_audit.txt, which this
tool fills for one run and empties again) and this tool prints each rejected call, caller first. Zig reports
one error per function, so run it again after naming the sites it lists until it prints none.

Needs `build_boot.py --arch 64` once (it writes the generated views and c modules). Analysis only, no object.
The raw bases (`raw`) are the hard part: they hide the struct, so trace where the pointer came from.

--c is a text scan, not proof: literal offsets added to a char pointer in C, `psx_load`/`psx_store` at an offset,
Zig casts through `@ptrFromInt(@intFromPtr(...))`, Zig byte pointers indexed by a literal (`state[0x23]`), memcpy/bzero with a hex size, and hex offsets in the Python
tests and tools that read game memory (`read_symbol`, `struct.unpack`). Names given narrow it to lines that
also mention the name; with none it lists them all.
"""
import argparse
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
import zig_toolchain  # noqa: E402

AUDIT = ROOT / "game/common/psx_audit.txt"
MODULES = ROOT / "pc/build/boot64/zig/battle_modules.json"
OWNERSHIP = ROOT / "pc/build/boot64/ownership.zig"
ERROR = re.compile(r"^(?P<file>[^\s:]+\.zig):(?P<line>\d+):\d+: error: (?P<msg>.*)$")
ALL = re.compile(r"^(?P<file>[^\s:]+\.zig):(?P<line>\d+):\d+: (?P<kind>note|error): (?P<msg>.*)$")


def zig_errors(names):
    modules = json.loads(MODULES.read_text())
    table = {
        "root": (str(ROOT / "game/battle/root.zig"), ["common", "ownership", *sorted(modules)]),
        "common": (str(ROOT / "game/common/common.zig"), []),
        "ownership": (str(OWNERSHIP), []),
        **{name: tuple(value) for name, value in modules.items()},
    }
    args = [str(zig_toolchain.ensure()), "build-obj", "-fno-emit-bin", "-fno-compiler-rt",
            "--cache-dir", str(ROOT / "pc/build/boot64/zig-cache-audit"),
            "--global-cache-dir", str(zig_toolchain.global_cache())]
    for name in ["root"] + sorted(n for n in table if n != "root"):
        path, deps = table[name]
        args += ["-target", "x86_64-linux-none", "-mcpu", "x86_64", "-O", "ReleaseSafe", "-fllvm", "-fPIE"]
        for dep in deps:
            args += ["--dep", dep]
        args.append(f"-M{name}={path}")
    old = AUDIT.read_text()
    AUDIT.write_text("\n".join(names) + "\n")
    try:
        done = subprocess.run(args, cwd=ROOT, capture_output=True, text=True)
    finally:
        AUDIT.write_text(old)
    return done.stderr


def report_zig(names):
    text = zig_errors(names)
    sites = []
    lines = text.splitlines()
    for i, line in enumerate(lines):
        match = ERROR.match(line)
        if not match or "byteAt: base" not in match["msg"]:
            continue
        base = match["msg"].split("base ", 1)[1]
        # The call is the first game/ frame of the trace that follows.
        where = None
        for follow in lines[i + 1:i + 40]:
            note = re.match(r"\s+(?:referenced by|called from).*", follow) or ALL.match(follow)
            frame = re.search(r"(game/[^\s:]+\.zig):(\d+)", follow)
            if frame and "psx.zig" not in frame[1]:
                where = f"{frame[1]}:{frame[2]}"
                break
            if ERROR.match(follow) and follow is not line:
                break
        sites.append((where or f"{match['file']}:{match['line']}", base))
    other = [line for line in lines if ": error:" in line and "byteAt: base" not in line]
    for where, base in sorted(set(sites)):
        print(f"{where}: {base}")
    print(f"{len(set(sites))} Zig sites for {', '.join(names)}"
          + (f" ({len(other)} other compile errors: the build is broken, fix it first)" if other else ""))
    if other:
        print("\n".join(other[:10]), file=sys.stderr)
    return len(set(sites))


C_PATTERNS = [
    ("C byte offset", re.compile(r"\((?:u_|unsigned )?(?:char|int|short|long|void|u_char|u_short|u_int|u_long|u8|u16|u32|s8)\s*\*\)"
                                 r"[^;\n]*[+-]\s*(?:PSX_OFFSET\()?0x[0-9a-fA-F]+")),
    ("C psx_load/store offset", re.compile(r"\bpsx_(?:load|store|slot_get|slot_set)\([^;\n]*0x[0-9a-fA-F]+")),
    ("C hex size", re.compile(r"\b(?:vs_main_)?(?:memcpy|bzero|memset|allocHeap|Memcpy)\s*\([^;\n]*0x[0-9a-fA-F]{2,}")),
    ("Zig address cast", re.compile(r"@ptrFromInt\(@intFromPtr\(")),
    ("Zig literal index", re.compile(r"\b[A-Za-z_]\w*\[(?:0x[0-9a-fA-F]+|\d{2,})\]")),
    ("Python offset", re.compile(r"(?:read_symbol|\.read|unpack(?:_from)?)\([^)\n]*(?:\+|,)\s*(?:0x[0-9a-fA-F]+|\d+)")),
]
TREES = [("pc/src", {".c", ".h", ".inc", ".cpp"}), ("game", {".zig"}), ("pc/tests", {".py"}), ("pc/tools", {".py"})]


def report_text(names):
    shown = 0
    for tree, suffixes in TREES:
        for path in sorted((ROOT / tree).rglob("*")):
            rel = path.relative_to(ROOT).as_posix()
            if path.suffix not in suffixes or not path.is_file() or "third_party" in rel or rel.endswith("pointer_sites.py"):
                continue
            for number, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
                for label, pattern in C_PATTERNS:
                    if label.startswith("Zig") != (path.suffix == ".zig") or (label.startswith("Python") != (path.suffix == ".py")):
                        continue
                    if pattern.search(line) and (not names or any(re.search(rf"\b{re.escape(n)}\b", line) for n in names)):
                        print(f"{rel}:{number}: [{label}] {line.strip()[:160]}")
                        shown += 1
                        break
    print(f"{shown} lines")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("names", nargs="*", help="struct names (as views_*/c_* name them), or raw")
    parser.add_argument("--c", action="store_true", help="the text scan of C, Zig casts and Python readers")
    args = parser.parse_args()
    if args.c:
        report_text(args.names)
        return
    if not args.names:
        parser.error("name a struct, or raw")
    if not MODULES.exists():
        sys.exit("run build_boot.py --arch 64 first (the generated views and c modules)")
    report_zig(args.names)


main()
