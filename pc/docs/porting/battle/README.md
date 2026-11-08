# Battle: what is left of the porting inventory

Battle's logic is Zig (`game/battle/`, `game/ownership.toml` lists the original functions it implements).
The C it replaced is deleted, and so is what only compared the two: zig_diff, the port pipeline, the
differential corpus and the model bake-off (2026-11-08; `git log` has them). The rules the port followed
are in `../PORTING.md`.

## Files

| File | What |
|---|---|
| `STATE.tsv` | one row per global or static a battle function read, wrote or took the address of. **The build reads it**: `pc/tools/battle_statics.py` makes the rows that say "file static" global, so the Zig reaches the C's storage through the views |
| `MEANINGS.tsv` | hand-written meanings and value lifetimes for `STATE.tsv`, and the readable Zig names (`zig_name`, PORTING.md section 16) the views give globals and fields. **The build reads it** (`pc/tools/zig_views.py`) |
| `FLIP.md` | the inventory of the PC features that sit inside battle's code (charge skip, camera stick, fast travel, weapon slots, the HUD layer, text, widescreen, ...), their settings and what each did to game state. Written before the flip; the hooks it lists now live in the Zig |

## Conventions

- `STATE.tsv` `meaning`: written by hand for the 103 globals that matter most; the rest say `unreviewed:`.
- `lifetime`: the storage's lifetime (`static`, `per-overlay-load`, `per-frame (scratchpad)`, `host`), then,
  where reviewed, the value's (`per-room`, `per-battle`, `per-action`, `per-frame`, `per-event`).
- The rows of the block-scope statics of deleted functions (`func_800AEF94__reported`) say "file static": the
  unit's C keeps the storage as a file-scope variable of that name.
