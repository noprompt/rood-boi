#!/usr/bin/env python3
"""libc on the game's stack: ROOD_STACK_SELFTEST=1 makes the game call strchr, strlen, strtoull, snprintf (%f), qsort and
memcpy on its own stack, from its entry and from the host tick it calls (boot_runtime.c stack_selftest), and report the stack's
alignment. A crash or a misaligned stack (rsp % 16 != 0 in a function body) fails. (The crash this guards against was not the
stack: a missing <string.h> made strchr return int, cutting the pointer; the build now rejects implicit declarations in the
host's C. The stack is aligned and big enough.)"""
import os
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "tools"))
from rood_rpc import OUT, Game  # noqa: E402

failures = []


def check(ok, message):
    print(("ok:   " if ok else "FAIL: ") + message)
    if not ok:
        failures.append(message)


def main():
    log = OUT / "stack-selftest.log"
    game = Game.launch(socket_path=f"/tmp/rood-stack-{os.getpid()}.sock", log=str(log), extra_env={"ROOD_STACK_SELFTEST": "1"}, fast=True)
    try:
        game.run(10)
    finally:
        game.close()
    text = log.read_text(errors="replace")
    for where in ("game entry", "the host tick"):
        m = re.search(rf"\[stack\] selftest at {where}: rsp % 16 = (\d+), ok", text)
        check(m is not None, f"libc calls on the game's stack from {where}")
        check(m is not None and m.group(1) == "0", f"the stack is 16-byte aligned at {where}")
    check("[crash]" not in text, "no crash")
    if failures:
        print(f"{len(failures)} check(s) failed")
        return 1
    print("PASS: stack_selftest_smoke")
    return 0


if __name__ == "__main__":
    sys.exit(main())
