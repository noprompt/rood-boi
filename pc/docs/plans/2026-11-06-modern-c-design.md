# Modern C: design (the rest of the game, after battle)

Status: approved by the user, 2026-11-06, with the three proposals below as decided.

## Intent

The user's goal: **a game that looks classic but feels modern.** Today it feels like an emulator with
graphical enhancements: the native code still lives in a PS1-shaped world, reads the PS1's program
files from the disc, and ticks on the PS1's clock. Battle is now Zig (flipped 2026-11-05; its C frozen
as the oracle, FLIP.md). The rest of the game's code (about 87,000 decompiled lines: MENU 39.5k, the
main program SLUS 24.3k, EFFECT 14.4k, TITLE 6.1k, ENDING 2.5k) moves to **modern C**, as a side stream
beside the main thread's work, area by area, MENU first.

Modern C, not Zig, for these areas (the user's call, 2026-11-05): battle's Zig port cost about three
weeks, most of it translation machinery (generated views of every struct, `psx.conv`, wrapping
arithmetic, translation-only bugs). Modern C starts from a copy that already compiles and already
behaves exactly like the game, so the work is all improvement and its checks reuse battle's tooling.
Zig stays an option where an area is redesigned rather than cleaned up. No C++ in game logic: save
states, rewind and photo mode copy the game's memory, which heap objects, STL containers and vtables
break.

## Goals

1. **The disc holds assets only.** No program image is read at run time: not `SLUS_010.40`'s RAM
   image at startup, not the `MENU*.PRG` / `TITLE.PRG` / `ENDING.PRG` / `EFFECT` overlays on load. An
   area is done when its overlay is never read; the project is done when nothing but textures, models,
   sound, movies, maps and text is.
2. **Readable code.** Real names (MEANINGS.tsv's, then better), real types (`stdint`, enums, structs
   with named fields), no PS1 address arithmetic, functions small enough to read.
3. **The PS1's world removed where it no longer helps:** overlays become ordinary code that is always
   there; guest pointers become native pointers where the data is the PC's own; fixed PS1 addresses go
   where nothing needs them; hard-coded look and feel moves to data (tunable-not-hardcoded).
4. **Behaviour exactly the game's until a change is meant**, checked tick for tick against the frozen
   original, as battle was.

## Non-goals

- Changing behaviour while modernizing. A modernization commit does not change what the game does;
  improvements (QoL, rebalancing, timing) are separate commits behind settings, like charge-skip.
- New PS1-timing work (frame rate, the logic's 30 Hz). That is a later stream that needs this one.
- Modernizing battle's C (frozen) or the PC engine (`pc/src`, already ours).

## Anti-goals (failure even if it "works")

- An area half-modernized and left: every area is finished (its overlay never read, its checks green)
  before the next starts.
- A modern copy that drifts from the original unnoticed: every step is checked against the oracle.
- Committed game data. Tables come from the user's disc at build time, as today (`build/`, never
  committed).
- Workers inventing their own conventions: this document's rules, or a change to this document.

## The approach: copy, route, improve

Battle's routing machinery, with C as the owned language:

1. **Copy.** An area's units are copied from `src/` (frozen from then on, the oracle) to `game/<area>/`
   (the modern copy; e.g. `game/menu/mainmenu.c`). The copy compiles as the owned side: `ownership.py`
   gains `lang = "c"` subsystems whose functions are built renamed to `F__owned` (as the Zig exports
   are), routed by the existing trampolines. `ROOD_OWNER=<area>=original` still runs the original.
   *As built (MENU1 pilot, 2026-11-06):* the copy goes through the original's preprocessing and the same
   text rename (`__owned`, as the original gets `__orig`); `ownership.share_statics` keeps state in one
   place: the original's file and function statics get link names and stay in the overlay's sections
   (restored on each overlay load), the copy refers to them as externs, and the build fails if the
   copy defines data of its own. Only global functions route: a unit's `static` helpers live inside
   the copy (MENU1 routes one function, `vs_menu1_exec`), so the check of an area is per unit (tick
   mode), not per function. C routes have no shadow mode yet (owner 2 is refused for them); the
   development host links the copy into the executable (not the reloadable library; `dev_default` is
   original); the Windows twin path is written but untested. `lang` is documented in the header of
   `game/ownership.toml`; the ownership design is `pc/docs/plans/2026-10-16-ownership-design.md`.
2. **Route.** One subsystem per original unit (as battle), default original until the area's checks
   pass, then owned (the area's flip, the same day: no long dual life).
3. **Improve** in small verified steps (below), each its own commit.

Why a copy and not edits in place: the original must stay as it is to be the oracle, and the routing
lets one function, or one unit, run either side in the same process (tick, alternate and shadow modes
need both in one binary).

## The steps of an area

1. **Copy and route** (mechanical): the units, the subsystem entries, the build. Check: the copy is
   bit-identical in behaviour (tick mode, all the area's recipes).
2. **Data off the disc:** the overlay's tables become the copy's own definitions (generated at build
   time from the user's disc into `pc/build`, as `build/` is today, then named and typed); the code
   stops reading guest addresses inside the overlay image; the overlay load becomes a no-op for this
   area (`vs_main_loadOverlay` asks the area's owner). Check: tick mode, plus a run with the overlay
   file absent from the disc image (a test option) that still passes.
3. **Names and types**, function by function: parameters, locals, struct fields, enums; MEANINGS.tsv
   updated. Check: tick mode, and the per-function C diff for the unit's global functions (zig_diff's harness with a C port: the
   original body against the modern one, random and edge inputs, same memory and calls).
4. **Structure:** split long functions, remove dead PS1 paths (DrawSync waits, double-buffer juggling
   the PC does not need) where the oracle shows no behaviour change, replace guest pointers with native
   ones where the data is the copy's own. Check: tick and alternate mode.
5. **The area's flip**: default owned; its recipes in the suite; FLIP-style notes in the area's README.

## Rules of modern C here

- C23: the modern copies build with `-std=gnu23` (the build is `-std=gnu17` today; the switch is part
  of the first area's step 1), the game's flags otherwise (`-fwrapv -funsigned-char -fno-strict-aliasing`).
- `stdint` types for sizes that matter (`int16_t` for an SVECTOR's component), `int` for counts and
  indices, `bool` for flags; enums for every state machine and mode.
- Names from MEANINGS.tsv; a function without a known meaning keeps its address name until it has one.
- No macros where a `static inline` function or a constant does; no PS1 address literals
  (`0x1F800000` becomes the scratchpad's accessor).
- Game state stays in snapshot-covered memory (the state sections, the game's heap): no `malloc` for
  state, no host pointers into engine memory stored in game state.
- Comments as the rest of the repo: short, plain, what and why.
- Each commit leaves the area green: the build, the area's tick checks.

## Verification (reused from battle)

- **Tick and alternate mode** (`pc/tests/diff/differ.py`, the group mode added 2026-11-06 for a whole
  area at once): the frozen original against the modern copy, per tick, the `inert` profile.
- **Per-function C diff**: zig_diff's harness taking a C port (both sides C: the simplest case it has),
  for the routed (global) functions; a unit's static helpers are covered by the unit's tick checks.
- **Recipes per area**: MENU needs its own (open each menu, move through it, equip, use an item, save):
  written with the area's step 1, the first worker task.
- **64-bit only**: the 32-bit build was retired 2026-11-06 (the user's call; whoever wants it keeps it up).

## Order and the first area

MENU first (the user's call): its units are `MAINMENU.PRG` (5.1k lines), `MENUC` (4.9k), `MENU7`
(4.3k), `MENUD`, `MENU9`, `MENUF`, `MENU4`, `MENU5`, `MENUB`, `MENU8`, `MENU3`, `MENU0`, `MENU2`,
`MENUE`, `MENU1`. The SLUS pieces menus call (items, equipment, save data) are modernized when a menu
needs them, as their own subsystems. After MENU: TITLE and ENDING (small), then the rest of SLUS, then
EFFECT (once the graphics work settles). Each by what the user wants next.

Tooling first (main thread, before workers start): `lang = "c"` routing in `ownership.py` and the
build; the C diff in zig_diff; MENU recipes for differ.py; the "overlay absent" test option.

## Workers

Up to two Sonnet workers (worker-load rules), one unit at a time each, in their own worktrees, on the
area's steps in order; the main thread reviews and merges, one full verify on main per merge batch.
Long runs in play mode.

## Cost and how we measure it

An estimate, said as one: the tooling about a day; then MENU's 15 units at roughly a unit a day per
worker for steps 1 to 3 (the copy is free; recipes and data are the cost), so about two weeks for MENU
with two workers, step 4 continuing after. What is measured per unit: functions renamed and typed,
tables off the disc, the overlay never read, the checks green; `port_progress.py` gains a modern-C
section so the number is visible, as battle's was.

## Decisions (the user, 2026-11-06: the proposals)

1. The copies live in `game/<area>/` beside the Zig: one tree for owned code (`game/menu/`).
2. An area is done after steps 1 to 3; step 4 continues as the area is worked on.
3. `-std=gnu23` for the modern copies only; the frozen originals build as they did.
