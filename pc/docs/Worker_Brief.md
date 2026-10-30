# Worker brief

The standing brief for an agent given one task in its own worktree. A task prompt names the goal,
the worktree, the deadline and what to hand back; everything that holds for every task is here.
Read this first, then the plan the task names (`pc/docs/plans/...`) and its latest Progress entries.

## The worktree

- Work only in the worktree the task names (`pc/tools/new_worktree.sh NAME` made it under the
  worktrees root, on branch `NAME`). Never merge, never push: the lead merges and publishes.
- Build first: `python3 pc/tools/build_boot.py --arch 64` and `--battle` (32-bit). The object
  cache is shared (`~/.cache/rood-boi` → the shared cache), so a fresh worktree builds in seconds.
- If `pc/build`'s CMake cache points at a cmake that is gone: `cmake -S pc -B pc/build`.
- The worktree's `data` and `disks` are symlinks into the main checkout; the main checkout's
  `pc/build/test-card1.mcd` and `pc/build/test-snapshots` are the tests' card and save states.

## Running the game and tests

- Tests: `pc/tests/run.py -j 1 --renderer gl|vulkan <suites>` (EGL headless), under `nice -n 10`,
  **one suite at a time** (`-j 1`): two workers and a porting run may share the machine.
- Scripts driving the game directly: `ROOD_ARCH=64` selects `pc/build/boot64`; `launch_at("save_room",
  card=...)` (`pc/tests/checkpoints.py`) with `ROOD_TEST_SNAPSHOT_DIR` set to the main checkout's
  `pc/build/test-snapshots`. Keep `ROOD_RPC` socket paths short (Unix sockets: 108 bytes) or leave
  the default.
- `present_screenshot` (`pc/tools/rood_rpc.py`) captures the presented picture (16:9 included);
  `screenshot` is the game's 4:3 frame buffer.
- Do not edit `pc/plugins/*/main.lua` while a test runs: the running game hot-reloads it, and a
  half-written plugin fails every later check.
- Kill stray game processes by PID only (`pgrep -af rood_battle_probe`, then `kill PID`).
- Known flaky: `ui_system_smoke`'s settings-save debounce (0.99 s against 1 s) under load; rerun
  once if it is the only failure.

## Gates

- Code changes: the targeted suites the task names, on **both** GL and Vulkan.
- A Zig port or anything a port calls: `python3 pc/tools/zig_diff.py FUNCTION --self-check --coverage`.
  A hook added to a C function that has a Zig port must be added to the port too (zig_diff fails
  otherwise: the C makes a call the Zig does not).
- Changes under `src/` (the decompilation): Docker `make commit-check` must say **All files match**.
  - Image `rood-reverse-dev:local`, always `-u $(id -u):$(id -g)`.
  - In a worktree run it in a scratch copy with the main checkout's `data` and `disks` mounted
    read-only (Docker cannot follow the symlinks, and `make clean` would empty `build/` first);
    if the worktree's `tools/{old-gcc,python,mkpsxiso,xdelta,objdiff,maspsx}` are empty, mount the
    main checkout's with `-v`.
  - The formatter rewrites unrelated files (`5BF94.c`, `58EC.c` are known): discard those, keep
    its changes to the lines you wrote.
- Inside a `#pragma vsstring` region the string transformer also rewrites line markers, so a
  multi-line `#ifdef` block or macro there breaks both builds ("invalid #line"): define one-line
  hook macros above the function (empty on the PS1 build) and use those inside it.
- Check a build by its summary, not by grepping for "error": `build_boot.py` reports
  "units failed to compile".
- The toolchain is GCC 16 (C23 by default): the game compiles as `-std=gnu17` (`-fpermissive` on
  GCC 14+); declare what you call.

## Rules

- Never commit game data or anything derived from it (pictures, maps, dumps): those stay in
  `pc/build`.
- No home paths or session scratch paths in committed files (`pc/tools/publish.sh`'s leak scan lists the denied patterns).
- Never touch the main checkout's `pc/save`, `pc/user` or `pc/lights` (reading the catalog copy is fine).
- No downloads, no package installs, no system settings: report what is missing instead.
- Look-and-feel values go in data (look tables, settings, RPC), never constants.
- Commit every green step. Messages end with the `Co-Authored-By` line the task gives.
- Add a Progress entry to the task's plan; document new API in `pc/docs/Extensions.md`.

## Hand back

What changed (commits), how it is tested (results per GPU, counts), what is left, bugs found, and
anything the lead must do (a system package, a decision for the user). Stop by the task's deadline
and say exactly where you got to.
