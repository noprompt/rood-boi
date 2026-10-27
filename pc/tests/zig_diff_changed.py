#!/usr/bin/env python3
"""ctest_long for the quick lane (run.py --quick, suite zig_diff_changed):
pc/tools/zig_diff.py (--self-check --coverage, as the CTest shards run it) on
the given functions only, the specs the change affects
(pc/tools/zig_diff_select.py), in --jobs parallel shards, beside zig_diff_coverage
(port_pipeline, ~15 min, is suite ctest_pipeline's, selected by the pipeline's
files and game/ownership.toml). The full lane runs every
spec in CTest's ten zig_diff shards instead.

    python3 pc/tests/zig_diff_changed.py [--jobs N] [--build DIR] [--no-ctest] FUNCTION...

No function: only zig_diff_coverage. Exit 0 when all pass, 77 when
zig_diff had no 64-bit build to read (skipped), 1 otherwise.
"""
import argparse
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
# ctest_long's entries besides the zig_diff shards (run.py CTEST_LONG), but
# port_pipeline: ctest_pipeline runs it when the pipeline or ownership changes.
OTHER_LONG = "^zig_diff_coverage$"


def commands(functions, jobs, build, ctest=True):
    """[(label, command)] to run side by side."""
    out = []
    n = min(jobs, len(functions))
    for k in range(n):
        out.append((f"zig_diff {k}/{n}", [sys.executable, str(ROOT / "pc/tools/zig_diff.py"), *functions,
                                          "--self-check", "--coverage", "--shard", f"{k}/{n}", "--build", str(build),
                                          "--work", str(ROOT / f"pc/build/zig-diff-quick-{k}")]))
    if ctest and (ROOT / "pc/build/CTestTestfile.cmake").exists():
        out.append(("ctest", ["ctest", "--test-dir", str(ROOT / "pc/build"), "--output-on-failure", "-j", "2",
                              "-R", OTHER_LONG]))
    return out


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("functions", nargs="*")
    parser.add_argument("--jobs", type=int, default=3, help="parallel zig_diff shards (default 3; ctest takes one more)")
    parser.add_argument("--build", type=pathlib.Path, default=ROOT / "pc/build/boot64")
    parser.add_argument("--no-ctest", action="store_true", help="zig_diff only, not ctest_long's other entries")
    args = parser.parse_args(argv)
    print(f"zig_diff: {len(args.functions)} changed spec(s): {' '.join(args.functions) or '(none)'}", flush=True)
    procs = []
    for label, cmd in commands(args.functions, max(1, args.jobs), args.build, not args.no_ctest):
        log = tempfile.TemporaryFile("w+")  # a pipe left unread would stall its process
        procs.append((label, log, subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, text=True)))
    failed, skipped = [], []
    for label, log, proc in procs:
        proc.wait()
        log.seek(0)
        print(f"---- {label} (exit {proc.returncode})\n{log.read().rstrip()}", flush=True)
        log.close()
        if proc.returncode == 77 and label.startswith("zig_diff"):
            skipped.append(label)
        elif proc.returncode:
            failed.append(label)
    if failed:
        print(f"zig_diff_changed: FAILED: {', '.join(failed)}")
        return 1
    if skipped:
        print("zig_diff_changed: skipped (no 64-bit build)")
        return 77
    print(f"zig_diff_changed: {len(args.functions)} spec(s) passed"
          + ("" if args.no_ctest else ", and ctest_long's other entries"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
