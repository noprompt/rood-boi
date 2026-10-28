# rood.imgui: developer tool windows in Lua

Goal: the overlay's tool windows written as Lua plugins and hot-reloaded,
no rebuild. Order: (1) `rood.imgui` + a Lua → developer RPC bridge;
(2) Window > Material review ported to Lua as the first real user; (3) the
cutscene sequencer, then the inspection and material editor panels
(`2026-10-27-materials-and-inspection-design.md`).

## API shape

- `rood.imgui`: Dear ImGui under its own names, so its documentation
  applies: `ImGui::SliderFloat` is `imgui.SliderFloat`,
  `ImGuiWindowFlags_MenuBar` is `imgui.WindowFlags_MenuBar`, `ImGuiCol_Text`
  `imgui.Col_Text`, `ImGuiKey_Enter` `imgui.Key_Enter` (keys also by name:
  `"A"`, `"Enter"`). Values in and out Lua's way:
  `changed, v = imgui.SliderFloat("x", v, 0, 1)`,
  `changed, rgb = imgui.ColorEdit3("tint", {r, g, b})` (a new table),
  `changed, i = imgui.Combo("preset", i, names)` (1-based: `names[i]`),
  `visible, open = imgui.Begin(name, open)`. Text is never a format string.
  Dear ImGui's own indexes stay as they are (`TableSetColumnIndex` 0-based).
- `rood.dev.window{id, title, draw, open, keys, size, flags}`: the host
  calls `ImGui::Begin`, then `draw()`, then `End`; the plugin draws only the
  contents. Returns the qualified id `<plugin>/<id>`.
  `rood.dev.window_open(id[, open])`, `rood.dev.remove_window(id)`.
- `rood.dev.rpc(method[, params]) -> result | nil, error`: one developer RPC
  method in-process (`pc_rpc_call`, dev_rpc.c): the same handler the socket
  reaches, its undo transaction included, no socket. The params table goes
  as JSON, the result comes back as a table.

## The gate: the `dev.tools` capability

Declared in the manifest like every capability. Not elevated (no
`plugins_elevated` needed), like the photo mode's: a shipped plugin has it
when it declares it; a user plugin when the player grants it (tied to its
code's hash, asked again after a change) — or in dev mode (`ROOD_RPC` set
or `ROOD_DEV=1`), where declaring it is enough: a tool being written keeps
it through every save and hot reload, and in that mode the RPC socket and
the REPL reach everything anyway. Without it, `rood.imgui` and
`rood.dev.window/rpc` do not exist.

`rood.dev.rpc` refuses `lua` (a plugin running plugins' code; no re-entry),
`quit`, `restart`, `reload`, `auth`, and what other grants cover (`read`,
`write`: memory.read/write; `state_flag`: flags.write; `record`,
`replay`, `input_record`: files). Nested calls are refused (dev_rpc.c's
buffers are static). Methods that answer later (`wait`, `step`'s waits,
`snapshot`) refuse: no client.

## The Window menu

Every registered window is a checkable entry of Window, after Cutscene and
the Lua console, sorted by title (tooltip: its id and plugin). The open
state is the player's: kept by qualified id across reloads (a reload's
`open = false` does not close it) and across runs (settings.cfg
`dev_window <id> 0|1`, saved when toggled). Windows draw while the overlay
shows, where the C++ tool windows draw (`pc_lua_dev_windows` after the Lua
console), inside the overlay's ImGui frame. `keys = true`: while the window
is focused (and nothing is typed, the camera not flying) the editor's own
shortcuts (Ctrl+Z, H, ...) stand aside, as for the Material review
(`pc_lua_dev_keys`).

## Errors and Dear ImGui's stack

- Every Begin/Push is recorded in a scope stack and checked at its End/Pop
  *before* Dear ImGui sees it: `imgui.End()` without `Begin`, `EndTable`
  while a `TreeNode` is innermost, `TableNextColumn` outside a table raise a
  Lua error instead of Dear ImGui's assertion.
- The host stores Dear ImGui's state (`ErrorRecoveryStoreState`) before the
  window's Begin. A draw that raises, or returns with scopes left open, is
  rewound with `ErrorRecoveryTryToRecoverState` (assertion and error tooltip
  off for that call): every Begin, table, tree, ID and style push closed.
  The window then shows the error (message and traceback) with Retry, until
  Retry, reopening it, or the plugin reloading. The plugin's other windows,
  the overlay and the game go on.
- Calls outside the plugin's own draw (a timer, another plugin's draw)
  raise. `rood.dev.window` and `remove_window` refuse inside a draw.

## Budgets

A window's draw is one call under the plugin's call budget
(`plugin_budget_ms`, 4 ms of its own Lua); Dear ImGui's work inside
`imgui.*` and the RPC handlers inside `rood.dev.rpc` are host work, excluded
up to `plugin_host_budget_ms`. A draw over budget is drawn again next frame;
a draw that raises counts one fault (the fault policy disables a plugin
that keeps failing, as for every handler).

## Tests

`pc/tests/lua_imgui_smoke.py` (GL and Vulkan; fixture `test.imgui`): gating,
the menu's registry (RPC `lua windows`), open by RPC and saved, values
round-tripping, `rood.dev.rpc`, keys, a failing and an unbalanced draw, Retry,
hot reload, the shipped example on.

## Phase 2: the Material review in Lua

`pc/plugins/rood.material_review` (off by default; the C++ window stays the
fallback until it is made the default): `rood.dev.window{replaces =
"material_review"}` takes the C++ window's place in Window and binds its
open flag, so Details > Material's button, RPC `material_review open` and
the review's live preview follow the Lua window. Everything goes through
RPC `material_review`, which grew what the window needed: the presets and
the filters in its status, `filters`, `list`'s counts and row fields,
`settings {save: false}`. `material_review_smoke` compares the two windows'
pictures (identical, pixel for pixel) and drives the Lua one's keys.

## Later

Menus other than Window; docking; `imgui.Image` of game textures; an
`imgui.InputText` callback API; a typed RPC facade (`rood.dev.material_review.select(id)`)
generated from the RPC's own list.
