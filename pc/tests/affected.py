#!/usr/bin/env python3
"""The suites a change can affect (run.py --changed [BASE]) and verify.sh's
quick lane (run.py --quick).

    python3 pc/tests/affected.py [BASE]              the selection for BASE (default main)
    python3 pc/tests/affected.py BASE --quick        the quick lane's suites per renderer
    python3 pc/tests/affected.py --files PATH...     what these paths would run
    python3 pc/tests/affected.py --all-files         tracked files no rule covers

Reads pc/tests/affected.toml (the table: core files, path rules, sets, the
quick lane) and derives the rest from the tree itself: test scripts and the
modules they import, and the files pc/CMakeLists.txt compiles into the CTest
probes. Only tracked changes count. Nothing selects every suite: a core file
selects the broad set, a file no rule covers the default set (with a warning);
every suite on every renderer is verify.sh --full.
"""
import ast
import fnmatch
import pathlib
import re
import subprocess
import sys
import tomllib

ROOT = pathlib.Path(__file__).resolve().parents[2]
TABLE = ROOT / "pc/tests/affected.toml"

# How a suite was selected. Only "direct" (its own script, an import, its
# declared sources, a CTest source) and "rule" pick a long suite in the
# quick lane, and "rule" only when the file is in the long suite's own paths.
DIRECT, RULE, BROAD = "direct", "rule", "broad"


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, check=True).stdout


def load_table():
    return tomllib.loads(TABLE.read_text())


def _match(path, patterns):
    return next((p for p in patterns if fnmatch.fnmatchcase(path, p)), None)


def ignored(path, table=None):
    table = table or load_table()
    return _match(path, table.get("ignore", {}).get("paths", [])) is not None


def changed_files(base="main", table=None):
    """Tracked files that differ from BASE: the commits since BASE and the
    uncommitted edits to tracked files (renames as both names). Untracked
    files never count, and [ignore] paths are dropped.

    BASE...HEAD (from the merge base) is what this branch changed. A published
    snapshot (pc/tools/publish.sh's public branch) shares no recent history
    with main, so its merge base is ancient; there the tree diff BASE..HEAD is
    the change. When BASE is not an ancestor, the smaller of the two is used:
    for a branch behind main the merge-base diff, for a snapshot the tree diff."""
    names = None
    try:
        fork = git("merge-base", base, "HEAD").strip()
        names = set(git("diff", "--name-only", "--no-renames", fork, "HEAD").split())
    except subprocess.CalledProcessError:
        fork = None  # no shared history at all
    if fork != git("rev-parse", base + "^{commit}").strip():
        tree = set(git("diff", "--name-only", "--no-renames", base, "HEAD").split())
        if names is None or len(tree) < len(names):
            names = tree
    names |= set(git("diff", "--name-only", "--no-renames", "HEAD").split())  # staged and unstaged
    table = table or load_table()
    return sorted(p for p in names if not ignored(p, table))


def _imports(path):
    """Top-level module names a Python file imports."""
    try:
        tree = ast.parse(path.read_text(errors="replace"))
    except SyntaxError:
        return set()
    names = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            names |= {a.name.split(".")[0] for a in node.names}
        elif isinstance(node, ast.ImportFrom) and node.module and not node.level:
            names.add(node.module.split(".")[0])
    return names


_LINKS = {}


def script_links(suites):
    """({repository path: suites that run it or declare it a source},
    {repository path of a pc/tests or pc/tools module: suites that import it,
    directly or not}). Cached per suite list (the scan parses every script)."""
    key = tuple((s.name, tuple(map(str, s.command)), tuple(map(str, s.sources))) for s in suites)
    if key not in _LINKS:
        _LINKS[key] = _script_links(suites)
    return _LINKS[key]


def _script_links(suites):
    modules = {p.stem: p for d in ("pc/tools", "pc/tests") for p in sorted((ROOT / d).glob("*.py"))}
    graph = {stem: {m for m in _imports(p) if m in modules and m != stem} for stem, p in modules.items()}
    direct, imported = {}, {}
    for suite in suites:
        roots = [pathlib.Path(w) for w in suite.command if w.endswith((".py", ".sh"))] + list(suite.sources)
        seen, todo = set(), [r.stem for r in roots if r.suffix == ".py" and r.stem in modules]
        for r in roots:
            rel = str(r.resolve().relative_to(ROOT)) if r.is_absolute() else str(r)
            direct.setdefault(rel, set()).add(suite.name)
        roots_stems = set(todo)
        while todo:
            stem = todo.pop()
            if stem in seen:
                continue
            seen.add(stem)
            todo += graph[stem]
        for stem in seen - roots_stems:
            imported.setdefault(str(modules[stem].relative_to(ROOT)), set()).add(suite.name)
    return direct, imported


def script_users(suites):
    """{repository path: every suite that runs, declares or imports it}."""
    direct, imported = script_links(suites)
    users = {k: set(v) for k, v in direct.items()}
    for k, v in imported.items():
        users.setdefault(k, set()).update(v)
    return users


def cmake_files():
    """Repository paths pc/CMakeLists.txt names (probe sources and what they
    compile, test scripts, asset directories)."""
    text = (ROOT / "pc/CMakeLists.txt").read_text()
    found = set()
    for word in re.findall(r"(?:src|tests|assets|third_party)/[\w./-]+", text):
        found.add("pc/" + word.rstrip("/"))
    return found


class Selection:
    def __init__(self):
        self.reasons = {}  # suite name -> [why]
        self.kinds = {}  # suite name -> {(kind, path)}
        self.by_file = {}  # path -> {suite names}
        self.files = []  # the files considered (after [ignore])
        self.ignored = []  # files [ignore] dropped
        self.unknown = []  # files no rule covers (they selected [default])
        self.core = []  # files that selected the broad set as core
        self.quiet = []  # files that select nothing
        self.selecting = set()  # files that selected a suite
        self.full = []  # kept for callers: nothing selects every suite any more

    def add(self, names, why, path, kind=RULE):
        for name in names:
            self.reasons.setdefault(name, []).append(why)
            self.kinds.setdefault(name, set()).add((kind, path))
            self.by_file.setdefault(path, set()).add(name)
            self.selecting.add(path)


def expander(names, table):
    sets = table.get("sets", {})

    def expand(patterns, seen=()):
        out = set()
        for p in patterns:
            if p.startswith("@"):
                if p[1:] not in sets:
                    raise KeyError(f"affected.toml: no set {p}")
                if p not in seen:
                    out |= set(expand(sets[p[1:]], (*seen, p)))
            else:
                out |= {n for n in names if fnmatch.fnmatchcase(n, p)}
        return sorted(out)
    return expand


def select(files, suites, table=None):
    """Which of `suites` (run.py Suite objects) `files` can affect."""
    table = table or load_table()
    names = [s.name for s in suites]
    expand = expander(names, table)
    sel = Selection()
    core = table.get("core", {})
    baseline = table.get("baseline", {})
    shared = table.get("shared", {})
    rules = table.get("rule", [])
    direct, imported = script_links(suites)
    cmake = cmake_files()

    for path in files:
        if ignored(path, table):
            sel.ignored.append(path)
            continue
        sel.files.append(path)
        known = exclusive = False
        hit = _match(path, core.get("paths", []))
        if hit:
            known = exclusive = True  # the broad set replaces its importers
            sel.core.append(path)
            sel.add(expand(core.get("suites", ["@broad"])), f"{path} (core: {hit})", path, BROAD)
        for rule in rules:
            hit = _match(path, rule["paths"])
            if hit:
                known = True
                exclusive |= rule.get("exclusive", False)
                sel.add(expand(rule["suites"]), f"{path} ({hit})", path, RULE)
        if path in direct:
            known = True
            sel.add(sorted(direct[path]), f"{path} (runs it)", path, DIRECT)
        if path in imported and not exclusive:
            known = True
            users = imported[path] - direct.get(path, set())
            if len(users) > shared.get("max_importers", 30):
                sel.add(expand(shared.get("suites", ["@broad"])),
                        f"{path} (imported by {len(users)} suites: the broad set)", path, BROAD)
            else:
                sel.add(sorted(users), f"{path} (imports it)", path, DIRECT)
        if not known and path.startswith("pc/tests/") and path.endswith((".py", ".sh")) \
                and "/" not in path[len("pc/tests/"):]:
            known = True  # a script no suite runs or imports
        if path in cmake or fnmatch.fnmatchcase(path, "pc/tests/*_probe.*") or \
                fnmatch.fnmatchcase(path, "pc/tests/*_stub*"):
            known = True
            sel.add(expand(["ctest"]), f"{path} (CTest probe or source)", path, DIRECT)
        if not known:
            sel.unknown.append(path)
            sel.add(expand(table.get("default", {}).get("suites", ["@default"])),
                    f"{path} (no rule: the default set)", path, BROAD)
            continue
        hit = _match(path, baseline.get("paths", []))
        if hit:
            sel.add(expand(baseline.get("suites", [])), f"{path} (baseline: {hit})", path, BROAD)
        if path not in sel.selecting:
            sel.quiet.append(path)
    return sel


def long_suites(names, table):
    """{long suite name: the paths that put it in the quick lane}."""
    out = {}
    for entry in table.get("long", []):
        for pattern in entry["suites"]:
            for n in names:
                if fnmatch.fnmatchcase(n, pattern):
                    out.setdefault(n, []).extend(entry.get("paths", []))
    return out


def touches_long(sel, name, paths):
    """Whether the change touches long suite `name`: its own script, sources or
    imports changed, or a file in its [[long]] paths did."""
    if any(kind == DIRECT for kind, _ in sel.kinds.get(name, ())):
        return True
    return any(_match(f, paths) for f in sel.files)


class Lane:
    """One renderer's share of the quick lane."""
    def __init__(self, renderer, names, skipped_long, extras, gl_files=()):
        self.renderer, self.names = renderer, names
        self.skipped_long, self.extras, self.gl_files = skipped_long, extras, list(gl_files)


def quick_lane(sel, suites, renderer, table=None, null_safe=()):
    """The quick lane's suites for `renderer` (run.py --quick): Vulkan runs the
    selection (less what the null lane runs) plus [quick] vulkan; null its
    CPU-safe share plus [quick] null; GL the sanity subset plus what GL's own
    files select. Long suites only when the change touches them. Nothing at
    all when the change selects nothing (documentation)."""
    table = table or load_table()
    quick = table.get("quick", {})
    by_name = {s.name: s for s in suites}
    expand = expander(list(by_name), table)
    if not sel.reasons:
        return Lane(renderer, [], [], [])
    gl_files = [f for f in sel.files if _match(f, quick.get("gl_paths", []))]
    if renderer == "gl":
        wanted = set(expand(quick.get("gl_sanity", [])))
        extras = sorted(wanted)
        for f in gl_files:
            wanted |= sel.by_file.get(f, set())
        # renderer-independent checks (no game binary) ran in the Vulkan lane,
        # CPU-safe game suites in the null lane
        wanted = {n for n in wanted if n in by_name and by_name[n].binary is not None and n not in null_safe}
    else:
        extras = sorted(n for n in expand(quick.get(renderer, [])) if n in by_name)
        wanted = {n for n in sel.reasons if n in by_name} | set(extras)
        if renderer == "vulkan":
            wanted -= {n for n in null_safe if n in by_name and by_name[n].binary is not None}
        elif renderer == "null":
            # its CPU-safe game suites; the checks with no game binary ran in the Vulkan lane
            wanted = {n for n in wanted if n in null_safe}
    long = long_suites(list(by_name), table)
    skipped_long = sorted(n for n in wanted if n in long and not touches_long(sel, n, long[n]))
    names = sorted(wanted - set(skipped_long))
    return Lane(renderer, names, skipped_long, extras, gl_files)


def report(sel, total, out=print):
    if sel.ignored:
        out(f"--changed: ignored {len(sel.ignored)} file(s) in tool folders ({', '.join(sel.ignored[:3])}"
            f"{' ...' if len(sel.ignored) > 3 else ''})")
    for path in sel.unknown:
        out(f"warning: no rule in pc/tests/affected.toml covers {path}: it selected the default set; "
            "add a rule for it")
    out(f"--changed: {len(sel.reasons)} of {total} suites")
    for name in sorted(sel.reasons):
        why = sel.reasons[name]
        out(f"  {name:<40} {why[0]}" + (f" (+{len(why) - 1} more)" if len(why) > 1 else ""))
    if sel.quiet:
        out(f"  (no suite for: {', '.join(sel.quiet[:8])}{' ...' if len(sel.quiet) > 8 else ''})")


def lane_line(lane, total):
    label = {"vulkan": "Vulkan", "gl": "GL", "null": "null"}[lane.renderer]
    text = f"quick ({label}): {len(lane.names)} of {total} suites"
    if lane.renderer == "gl":
        sanity = len([n for n in lane.extras if n in lane.names])
        text += f" (GL sanity {sanity}, GL's own files {len(lane.names) - sanity})"
    if lane.skipped_long:
        text += f"; long, left to the full lane: {', '.join(lane.skipped_long)}"
    return text


def quick_summary(base=None, files=None, out=print):
    """One line for verify.sh: the quick lane's suites over the three renderers."""
    sys.path.insert(0, str(ROOT / "pc/tests"))
    import run
    table = load_table()
    files = files if files is not None else changed_files(base, table)
    lanes, every = {}, None
    for renderer in ("null", "vulkan", "gl"):
        args = run.default_args()
        args.renderer = renderer
        suites = run.renderer_suites(args, "egl")
        if renderer == "vulkan":
            every = suites
        sel = select(files, suites, table)
        lanes[renderer] = quick_lane(sel, suites, renderer, table, run.NULL_SAFE)
    vk, gl, null = lanes["vulkan"], lanes["gl"], lanes["null"]
    ran = set(vk.names) | set(gl.names) | set(null.names)
    sanity = len([n for n in gl.extras if n in gl.names])
    out(f"quick: {len(vk.names) + len(gl.names) + len(null.names)} suites (Vulkan {len(vk.names)}, "
        f"null {len(null.names)}, GL sanity {sanity}"
        + (f", GL for its own files {len(gl.names) - sanity}" if len(gl.names) > sanity else "")
        + f"), skipped {len([s for s in every if s.name not in ran])} of {len(every)} (full lane)")
    sel = select(files, every, table)
    for path in sel.unknown:
        out(f"warning: no rule in pc/tests/affected.toml covers {path}: add one")
    return lanes


def main():
    import argparse
    sys.path.insert(0, str(ROOT / "pc/tests"))
    import run
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("base", nargs="?", default="main")
    parser.add_argument("--all-files", action="store_true", help="list tracked files no rule covers")
    parser.add_argument("--files", nargs="+", help="these paths instead of the diff (what would they run?)")
    parser.add_argument("--quick", action="store_true", help="the quick lane's suites per renderer")
    parser.add_argument("--quick-summary", action="store_true", help="verify.sh's one-line quick lane summary")
    args = parser.parse_args()
    suites = run.renderer_suites(run.default_args(), "egl")
    if args.all_files:
        files = git("ls-files").split()
        print("\n".join(select(files, suites).unknown) or "every tracked file is covered")
        return 0
    files = args.files or changed_files(args.base)
    if args.quick_summary:
        quick_summary(files=files)
        return 0
    if args.quick:
        lanes = quick_summary(files=files)
        for lane in lanes.values():
            print(lane_line(lane, len(suites)))
            print("  " + " ".join(lane.names))
        return 0
    report(select(files, suites), len(suites))
    return 0


if __name__ == "__main__":
    sys.exit(main())
