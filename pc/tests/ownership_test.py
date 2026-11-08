#!/usr/bin/env python3
"""pc/tools/ownership.py: the table, its validation, the declaration-only strip and the generated
routes (the development library's trampolines and the comptime table)."""
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
import ownership  # noqa: E402

failures = []


def check(ok, message):
    print(("ok:   " if ok else "FAIL: ") + message)
    if not ok:
        failures.append(message)


def raises(fn, text):
    try:
        fn()
    except (ValueError, SystemExit) as e:
        return text in str(e)
    return False


TOML = """
[subsystem.alpha]
overlay = "battle"
unit = "src/A.c"
functions = [ { addr = 0x80010000, name = "f_one" }, { addr = 0x80010010, name = "f_two" } ]

[subsystem.beta]
overlay = "battle"
unit = "src/B.c"
functions = [ { addr = 0x80020000, name = "g_one" } ]

[subsystem.frame]
overlay = "battle"
unit = "src/B.c"
resident = true
functions = [ { addr = 0x80030000, name = "h_one" } ]
"""

with tempfile.TemporaryDirectory() as d:
    path = pathlib.Path(d) / "ownership.toml"
    path.write_text(TOML)
    table = ownership.load(path)
    check([s.name for s in table.subsystems] == ["alpha", "beta", "frame"], "subsystems in file order")
    check([s.index for s in table.subsystems] == [0, 1, 2], "indices are the Subsystem enum values")
    check(table.routes() == [("f_one", 0), ("f_two", 0), ("g_one", 1), ("h_one", 2)], "routes in table order")
    check(table.reloadable_routes() == [("f_one", 0), ("f_two", 0), ("g_one", 1)],
          "a resident subsystem's routes are not in the reloadable library")
    check([s.resident for s in table.subsystems] == [False, False, True], "resident read, false when absent")
    addresses = {"f_one": 0x80010000, "f_two": 0x80010010, "g_one": 0x80020000, "h_one": 0x80030000}
    units = {"src/A.c", "src/B.c"}
    check(table.problems(addresses, units) == [], "a consistent table validates")
    renamed = dict(addresses, f_two=None, f_two_renamed=0x80010010)
    del renamed["f_two"]
    problems = table.problems(renamed, units)
    check(any("0x80010010" in p and "f_two_renamed" in p for p in problems),
          f"an upstream rename names the new name: {problems}")
    shared = dict(addresses, overlay_twin=0x80010010)  # a second overlay's name at the same address
    check(table.problems(shared, units) == [],
          "two names at one address (ENDING over BATTLE) still validate the table's name")
    statics = [*addresses.items(), ("f_one", 0x80040000)]  # another unit's static f_one
    check(table.problems(statics, units) == [],
          "a static name another unit also defines validates at its own address (pairs)")
    check(table.problems(dict(statics), units) != [], "a dict keeps one address per name (why the build passes pairs)")
    check(any("src/B.c" in p for p in table.problems(addresses, {"src/A.c"})), "a unit that is not compiled is reported")
    check([s.name for s in table.for_build(units, {"battle"}).subsystems] == ["alpha", "beta", "frame"]
          and table.for_build({"src/A.c"}, {"battle"}).subsystems[0].name == "alpha"
          and table.for_build(units, set()).subsystems == [], "for_build keeps the subsystems of this build's units and overlays")
    host = TOML.replace('{ addr = 0x80020000, name = "g_one" }', '{ name = "pc_cb_1", host = true }')
    path.write_text(host)
    ht = ownership.load(path)
    check(ht.problems(addresses, units) == [] and ht.routes()[2] == ("pc_cb_1", 1),
          "a host function (host = true, no addr) is exported and not checked against the ELFs")
    path.write_text(TOML.replace('{ addr = 0x80020000, name = "g_one" }', '{ name = "g_one" }'))
    check(raises(lambda: ownership.load(path), "host"), "a function without addr must say host = true")
    path.write_text(TOML + '\n[subsystem.gamma]\noverlay="battle"\nunit="src/A.c"\nfunctions=[{addr=0x80010000, name="f_one"}]\n')
    check(raises(lambda: ownership.load(path), "f_one"), "a function routed twice is refused")

UNIT = b"""# 1 "unit.c"
typedef struct { int a; } S;
int F(int);
int F2(int x) { return x; }
static int helper(int x) { return F(x) + 1; }
int F(int x)
{
    const char* s = "F(1) { not code }";
    return x * 2;
}
int (*table[])(int) = { F, F2 };
int G(void) { return F(1) + F(2) + helper(3); }
int K(a, b)
    int a;
    int b;
{ return a + b; }
__attribute__((noinline)) int H(void) { return F(0); }
void Hook(int a)
{
    extern void pc_hook_start(int now);
    pc_hook_start(1);
    {
        extern void pc_hook_end(int message, int action) __attribute__((weak));
        if (pc_hook_end) pc_hook_end(a, 2);
    }
}
"""

decls = ownership.strip_bodies(UNIT)
check(b"return" not in decls and b"int F(int x);" in decls and b"int G(void);" in decls,
      "strip_bodies keeps every declaration and drops the bodies")
check(b"typedef struct { int a; } S;" in decls and b"{ F, F2 }" in decls,
      "strip_bodies keeps struct bodies and initialisers")
check(b'# 1 "unit.c"' not in decls, "strip_bodies drops linemarkers")
check(b"extern void pc_hook_start(int now);\n" in decls
      and b"extern void pc_hook_end(int message, int action) __attribute__((weak));\n" in decls
      and b"pc_hook_start(1)" not in decls, "strip_bodies keeps block-scope extern declarations at file scope")

t = ownership.Table([ownership.Subsystem("s", 0, "battle", "u.c", [(0, "F")], {}),
                     ownership.Subsystem("t", 1, "battle", "u.c", [(0, "G")], {}),
                     ownership.Subsystem("r", 2, "battle", "u.c", [(0, "R")], {}, {}, True)])
src = ownership.routing_source(t)
check("F:\\n" in src and "G:\\n" in src and "R:\\n" not in src and "pc_route_count = 2" in src,
      "a trampoline per reloadable route, none for a resident one")
check("jmp *0(%r11)" in src and "jmp *8(%r11)" in src, "each reads its own slot of the published table")
check("__orig" not in src and "__shadow" not in src and "pc_owner" not in src, "no original or shadow routing remains")

# Execute the generated trampolines, including a previously saved function pointer.
with tempfile.TemporaryDirectory() as d:
    path = pathlib.Path(d)
    source = path / "routes.c"
    source.write_text(ownership.routing_source(t) + r"""
#include <assert.h>
const char F__owned_abi[] = "test-F", G__owned_abi[] = "test-G";
int F(int, int, int, int, int, int, int);
int first(int a, int b, int c, int d, int e, int f, int g) {
    return a + 2*b + 3*c + 4*d + 5*e + 6*f + 7*g + 100;
}
int second(int a, int b, int c, int d, int e, int f, int g) {
    return a + 2*b + 3*c + 4*d + 5*e + 6*f + 7*g + 200;
}
double G(double);
double g_owned(double a) { return a + 2; }
int main(void) {
    int (*saved)(int,int,int,int,int,int,int) = F;
    pc_owned_slots[0] = first;
    pc_owned_slots[1] = g_owned;
    assert(F(1,2,3,4,5,6,7) == 240);
    assert(saved(1,2,3,4,5,6,7) == 240);
    pc_owned_slots[0] = second;
    assert(F(1,2,3,4,5,6,7) == 340);
    assert(saved(1,2,3,4,5,6,7) == 340);
    assert(G(0.5) == 2.5);
    void* next[] = { first, g_owned };
    assert(__atomic_exchange_n(&pc_owned_table, next, __ATOMIC_ACQ_REL) == pc_owned_slots);
    assert(F(1,2,3,4,5,6,7) == 240); /* the complete new table at once */
    assert(saved(1,2,3,4,5,6,7) == 240);
    assert(G(0.5) == 2.5);
    return 0;
}
""")
    compiled = subprocess.run(["gcc", "-Wall", "-Wextra", "-Werror", "-fno-pie", "-no-pie",
                               str(source), "-o", str(path / "routes")], capture_output=True, text=True, timeout=60)
    check(compiled.returncode == 0, "routing harness compiles: " + compiled.stderr.strip())
    if compiled.returncode == 0:
        result = subprocess.run([str(path / "routes")], timeout=10)
        check(result.returncode == 0, "repointing keeps saved addresses and integer/FP/stack arguments")

zig = ownership.ownership_zig(t)
check('.{ .name = "F", .zig = "F", .subsystem = 0, .resident = false }' in zig
      and '.{ .name = "R", .zig = "R", .subsystem = 2, .resident = true }' in zig,
      "the comptime table (no zig key: the Zig function has the original name; resident flagged)")

# Readable Zig names (PORTING.md §16): the table maps the original symbol to
# the Zig function; the export keeps the original name, the source says `orig:`.
with tempfile.TemporaryDirectory() as d:
    d = pathlib.Path(d)
    path = d / "ownership.toml"
    path.write_text(TOML.replace('{ addr = 0x80010010, name = "f_two" }',
                                 '{ addr = 0x80010010, name = "f_two", zig = "score.countKill" }'))
    named = ownership.load(path)
    check(named.zig_routes()[1] == ("f_two", "score.countKill", 0, False) and named.zig_routes()[0][1] == "f_one",
          "zig_routes maps original -> Zig function")
    check('.{ .name = "f_two", .zig = "score.countKill", .subsystem = 0, .resident = false }' in ownership.ownership_zig(named)
          and "pub fn routesOf" in ownership.ownership_zig(named), "routesOf carries the mapping to route.zig")
    path.write_text(TOML.replace('name = "f_two" }', 'name = "f_two", zig = "score.count kill" }'))
    check(raises(lambda: ownership.load(path), "Zig declaration path"), "a malformed zig path is refused")
    (d / "battle").mkdir()
    source = d / "battle/score.zig"
    source.write_text("/// orig: f_two (src/A.c)\n/// Counts a kill.\npub fn countKill() callconv(.c) void {}\n")
    check(ownership.orig_comment_problems(named, d) == [], "a documented Zig function passes")
    source.write_text("/// orig: f_two (src/B.c)\npub fn countKill() callconv(.c) void {}\n")
    check(len(ownership.orig_comment_problems(named, d)) == 1, "the orig line must name the routed unit")
    source.write_text("pub fn countKill() callconv(.c) void {}\n")
    check(len(ownership.orig_comment_problems(named, d)) == 1, "a Zig function without `orig:` is reported")

# A route's `zig` path resolves through the `pub const NAME = @import("file.zig")` lines from the
# overlay's root.zig, in subdirectories too (D2's ports are in game/<overlay>/pc/, PORTING.md §20).
with tempfile.TemporaryDirectory() as d:
    d = pathlib.Path(d)
    (d / "battle/pc").mkdir(parents=True)
    (d / "battle/root.zig").write_text('const x = 1;\npub const score = @import("score.zig");\npub const pc = @import("pc/root.zig");\n')
    (d / "battle/pc/root.zig").write_text('// pc/src/a.c\npub const tick = @import("tick_timer.zig");\n')
    check(ownership.zig_source("battle", "score.countKill", d) == (d / "battle/score.zig", "countKill"),
          "a one-module path names game/<overlay>/<module>.zig")
    check(ownership.zig_source("battle", "pc.tick.tickTimer", d) == (d / "battle/pc/tick_timer.zig", "tickTimer"),
          "a nested path follows each root.zig's import, relative to its file")
    check(raises(lambda: ownership.zig_source("battle", "pc.missing.f", d), "missing"),
          "a module root.zig does not import is reported")
    check(raises(lambda: ownership.zig_source("battle", "other.f", d), "other"), "an unknown first module is reported")

# The real table: every route's Zig function is where its path says.
table_now = ownership.load()
unresolved = []
for s in table_now.subsystems:
    for _, name in s.functions:
        if name in s.zig:
            try:
                file, _ = ownership.zig_source(s.overlay, s.zig[name])
                if not file.exists():
                    unresolved.append(name)
            except ValueError:
                unresolved.append(name)
check(not unresolved, f"every real route resolves to a Zig file: {unresolved[:5]}")
check(all((ROOT / s.unit).exists() for s in table_now.subsystems), "every subsystem's unit is a file of the checkout")
check(ownership.orig_comment_problems(table_now) == [], "every real route has its `orig:` doc line")
check([s.name for s in table_now.subsystems if s.resident] == ["battle_frame"],
      "battle_frame is the one resident subsystem (it sits at the vsync)")
real = ownership.load()
root_zig = (ROOT / "game/battle/pc/root.zig").read_text()
check("// pc/src/boot_sdk.c\n" in root_zig, "boot_sdk.c has its header in game/battle/pc/root.zig")
check(all(f"// {s.unit}\n" in root_zig for s in real.subsystems if s.name.startswith("d2_")),
      "every d2_ subsystem has its header")
# Every pc/src unit the build compiles for battle and the D2 tables name is a source of build_boot.py.
build_text = (ROOT / "pc/tools/build_boot.py").read_text()
check(all(f'("{s.unit}", ' in build_text for s in real.subsystems if s.name.startswith("d2_")),
      "every d2_ subsystem's unit is in build_boot.py's sources")

print("FAILED" if failures else "all ownership checks passed")
sys.exit(1 if failures else 0)
