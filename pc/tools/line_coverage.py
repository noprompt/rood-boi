#!/usr/bin/env python3
"""Which lines of the game's code a run reached: the proof that a route covers a conversion.

    python3 pc/tools/line_coverage.py targets [RULE]      the lines the lint counts for RULE (default gpu_packet_writes)
                                                          to pc/build/line_coverage/targets.txt
    COV_WRAP=1 python3 pc/tools/build_compare.py BINARY ...  (a lane run through the wrapper: build_compare.py's
                                                          BUILD_COMPARE_COVER=<log> does that) appends the lines reached
    python3 pc/tools/line_coverage.py report LOG...       targets reached / not reached, by file

The game runs under gdb (the wrapper script `wrap`): a one-shot breakpoint on each target line (file:line, from the
debug info) that logs the line and disables itself, so a hot line costs one stop. Only a debug build answers.
"""
import os
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
WORK = ROOT / "pc/build/line_coverage"

GDB = r'''
import gdb, os
log = os.environ["COV_LOG"]
class Probe(gdb.Breakpoint):
    def __init__(self, spec):
        super().__init__(spec, internal=True)
        self.spec_name = spec
    def stop(self):
        with open(log, "a") as f:
            f.write(self.spec_name + "\n")
        self.enabled = False
        return False
gdb.execute("set pagination off")
gdb.execute("set confirm off")
gdb.execute("set breakpoint pending off")
gdb.execute("handle SIGUSR1 SIGUSR2 SIGPIPE SIGALRM nostop noprint pass")
made = 0
for line in open(os.environ["COV_TARGETS"]):
    spec = line.strip()
    if not spec:
        continue
    try:
        Probe(spec)
        made += 1
    except gdb.error:
        pass
open(log, "a").write("# probes %d\n" % made)
gdb.execute("run")
'''


def targets(rule):
    out = subprocess.run([sys.executable, str(ROOT / "pc/tools/ps1_address_lint.py"), "--where", rule], capture_output=True, text=True).stdout
    lines = []
    for row in out.splitlines():
        parts = row.split(":", 2)
        if len(parts) >= 2 and parts[1].strip().isdigit():
            lines.append(f"{parts[0]}:{parts[1].strip()}")
    return lines


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    WORK.mkdir(parents=True, exist_ok=True)
    if cmd == "targets":
        lines = targets(sys.argv[2] if len(sys.argv) > 2 else "gpu_packet_writes")
        (WORK / "targets.txt").write_text("\n".join(lines) + "\n")
        (WORK / "probe.py").write_text(GDB)
        wrap = WORK / "wrap"
        wrap.write_text('#!/bin/sh\nexec gdb -q -batch -x "$COV_PROBE" --args "$COV_REAL" "$@"\n')
        wrap.chmod(0o755)
        print(f"{len(lines)} target lines in {WORK / 'targets.txt'}")
    elif cmd == "routes":  # routes LOG NAME,NAME...: each build_compare menus route once, this tree's build under gdb (a failed one is tried again)
        import shutil
        import tempfile
        log, names = sys.argv[2], sys.argv[3].split(",")
        binary = pathlib.Path(os.environ.get("BUILD_COMPARE_COVER_BINARY") or ROOT / "pc/build/boot64/rood_battle_probe")
        env = dict(os.environ, BUILD_COMPARE_COVER=log)
        for name in names:
            for attempt in range(2):
                out = tempfile.mkdtemp(prefix="cov-", dir=ROOT / "pc/build")
                done = subprocess.run([sys.executable, str(ROOT / "pc/tools/build_compare.py"), "--play-menus", str(binary), "--menus", name,
                                       "--menu-sample", "40", "--card", str(ROOT / "pc/build/test-card1.mcd"), "--out", out],
                                      capture_output=True, text=True, env=env)
                shutil.rmtree(out, ignore_errors=True)
                if "RESULT" in done.stdout:
                    break
            print(f"{name}: {'ok' if 'RESULT' in done.stdout else 'failed'}", flush=True)
    elif cmd == "report":
        want = [l for l in (WORK / "targets.txt").read_text().split() if l]
        hit = set()
        for log in sys.argv[2:]:
            hit |= {l.strip() for l in pathlib.Path(log).read_text().splitlines() if l and not l.startswith("#")}
        by_file = {}
        for l in want:
            by_file.setdefault(l.rsplit(":", 1)[0], []).append(l)
        reached = [l for l in want if l in hit]
        print(f"{len(reached)} of {len(want)} target lines reached")
        for f, ls in sorted(by_file.items(), key=lambda kv: -len(kv[1])):
            got = sum(1 for l in ls if l in hit)
            print(f"  {got:3}/{len(ls):3}  {f}" + ("" if got == len(ls) else "   missing " + " ".join(l.rsplit(':', 1)[1] for l in ls if l not in hit)))
    else:
        sys.exit(__doc__)


main()
