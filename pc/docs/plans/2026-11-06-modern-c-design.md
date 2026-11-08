# Modern C: design (the rest of the game, after battle)

Status: approved 2026-11-06; the approach changed 2026-11-08 (the user's call): the game's C moved whole to
`pc/src/game/` and is edited directly. No routing, no original running beside it, no per-area comparison.

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
4. **Behaviour exactly the game's until a change is meant**, kept by the smoke suites and golden frames.

## Non-goals

- Changing behaviour while modernizing. A modernization commit does not change what the game does;
  improvements (QoL, rebalancing, timing) are separate commits behind settings, like charge-skip.
- New PS1-timing work (frame rate, the logic's 30 Hz). That is a later stream that needs this one.
- Modernizing battle's C (frozen) or the PC engine (`pc/src`, already ours).

## Anti-goals (failure even if it "works")

- An area half-modernized and left: every area is finished (its overlay never read, its checks green)
  before the next starts.
- Committed game data. Tables come from the user's disc at build time, as today (`build/`, never
  committed).
- Workers inventing their own conventions: this document's rules, or a change to this document.

## The approach

`pc/src/game/` is the game's code: every unit of the original decomp tree, built by `build_boot.py`, edited
directly. A copy that starts identical has nothing to prove, so it needs no comparison machinery. Battle's
Zig routing stays as it is until battle's C is removed.

`src/` remains only because a fresh clone's setup (`make`, splat) reads it to extract the game data; no PC
build reads it. It goes when setup no longer needs it.

Work goes by what the game needs, across units when that is the natural change (pointers, overlays), not
unit by unit. Each overlay's tables become our own definitions, so its file is never read; names and types
improve as code is worked on.

## Rules of modern C here

- The game's flags stay (`-fwrapv -funsigned-char -fno-strict-aliasing`); C23 when a unit wants it.
- `stdint` types for sizes that matter (`int16_t` for an SVECTOR's component), `int` for counts and
  indices, `bool` for flags; enums for every state machine and mode.
- Names from MEANINGS.tsv; a function without a known meaning keeps its address name until it has one.
- No macros where a `static inline` function or a constant does; no PS1 address literals
  (`0x1F800000` becomes the scratchpad's accessor).
- Game state stays in snapshot-covered memory (the state sections, the game's heap): no `malloc` for
  state, no host pointers into engine memory stored in game state.
- Comments as the rest of the repo: short, plain, what and why.
- Each commit leaves the area green: the build, the area's tick checks.

## Verification

The quick lane (Testing.md): smoke suites and golden frames, about 15 minutes at most. A build from the same
commit with an older checkout is the reference if a behaviour question comes up.
