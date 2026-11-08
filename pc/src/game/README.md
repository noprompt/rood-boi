# The game's code

The whole decompiled game, moved here on 2026-11-08 and edited directly: this is the code the PC build
compiles (`build_boot.py`). Battle's functions are Zig (`game/battle/`): the C that is left in `BATTLE/` is
types, tables, statics and declarations that the Zig and the rest of the game use. Nothing compares it with an original.

The top-level `src/` is the decomp tree as it was. No PC build reads it; a fresh clone's setup (`make`, splat)
does, to extract the game data. Change the game here, not there.
