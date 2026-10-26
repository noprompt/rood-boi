# rood.craftbook

An example plugin, off by default. While you stand in a workshop it shows a
small panel listing what the game's Combine screen can make from your bag:
`First + Second: Result (Material)`, one line per result.

Turn it on in the Lua console's Plugins list (F1, Window > Lua console), or
with RPC `lua {action "enable", plugin "rood.craftbook", enabled true}`. Its
setting `plugin:rood.craftbook/show` ("Show at workshops") hides it again
without turning it off.

## As a template

It is small on purpose: copy the folder to `pc/user/plugins/<you>.<name>`,
change the `id` in `plugin.lua`, and edit.

| File | What it shows |
|---|---|
| `plugin.lua` | the manifest: id, `api_version`, `default_enabled = false` |
| `main.lua` | a setting (`rood.settings.define`), a timer (`rood.timer.every`), the player state queries (`rood.game.workshop()`, `rood.game.craftable()`, `rood.game.mode()`), a panel (`rood.draw.panel` with `{classic = true}`) in both looks: the game's window and prompt sprites in the classic look, `view.flavour` choosing, styles made once at load |
| `craft.lua` | a module of plain Lua that `main.lua` and the tests both `require` |
| `tests/craftbook_test.lua` | Lua tests (`rood.test`): `python3 pc/tests/lua_smoke.py --tests-only --plugin rood.craftbook`, or `rood_rpc.py lua-test` |

The queries are read-only and cheap to call: each gives the same table until
the next game vsync (compare with `==`). The combinations and their results
are the game's own: `rood.game.craftable()` runs the game's combine code
(MENUC's) on copies of your records and changes nothing. The fields of every
table are listed in `pc/docs/Extensions.md`, "Player state".

## The two looks

The panel follows the player's UI setting (`view.look` in the draw
function):

- **classic** (the modern menus off): drawn by the game's own frame
  (`rood.draw.panel(draw, {classic = true})`) with the game's pieces: its text
  box window (`d.window`: stone body, frame, shadow), the menus' font (through
  ui_text, so the typography settings apply) and the triangle button sprite
  of its footer (`d.glyph`, as the game's prompts draw it). The classic look
  may only change typography, so there are no colours of its own to copy; the
  metrics are the game's (320 x 240 pixels, the menu font 12 high).
- **modern**: the modern menus' dark panel and label font.

Both are plain data in `M.look` at the top of `main.lua`: edit and save, and
the plugin reloads.
