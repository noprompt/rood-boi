# Editor shell: implementation plan (slice 1)

Design: `2026-10-30-editor-shell-design.md` (approved). Worktree `editor-shell`, branch `editor-shell`,
from main 3bc05cd2e. Brief: `pc/docs/Worker_Brief.md`.

## Builder's decisions (the design's "left to the builder")

1. **The game picture gets into the panel through the presenters' inset.** Both presenters already
   place the picture inside `pc_gl_inset` (left, top, right, bottom margins; `gl_present.c` and
   `vk_present.c` `update_view`), centred at the game's aspect, and `pc_gl_view` is the result every
   picking, handle, HUD and menu path maps through. The Game panel's content rectangle becomes the inset.
   No texture, no second copy: picture quality, 16:9, integer scaling, photo captures and frame pacing
   are exactly today's; the one-frame lag of the inset (set during the overlay frame, used by the next
   present) is today's too. The Game window has no background, so the picture shows through it.
2. **The Game panel is a hit-test hole.** Over the picture Dear ImGui must report no hovered window
   (`io.WantCaptureMouse` false), as over the bare picture today: `lights.cpp`, `editor_view.cpp`,
   `editor_handles.cpp` (`IsWindowHovered(AnyWindow)`), `cutscene_camera.cpp` and `viewport_keys` all
   test that. Dear ImGui supports one rectangular hole per window (`SetWindowHitTestHole`,
   `imgui_internal.h`; `FindHoveredWindow` skips a window inside its hole). The Game panel registers its
   content rectangle as a hole on itself and, when docked, on its dock node's host window. Nothing in the
   existing mouse logic changes; ImGuizmo's `SetNextFrameWantCaptureMouse` over a gizmo still works.
3. **The toolbar stays a strip** under the menu bar (not a dock node): the dock space fills the window
   below it. Less to break (its `flow` layout assumes a wide row) and the mockup's look.
4. **The Library keeps its tab in the Outliner panel** (`rood_library::docked()`), so `editor_ui {tab}`
   and `editor_library {view docked}` keep their meaning; popped out, it is a plain window that docks
   anywhere like the others.
5. **imgui.ini migration:** the old fixed-position windows had `NoSavedSettings`; the tool windows'
   saved floating positions are dropped once by the layout's first build (a `[ShellLayout]` version
   number in the ini, see task 2). Per user, under `pc/build/boot/imgui.ini` or `ROOD_IMGUI_INI`.
6. **Command registry:** `pc/src/editor_commands.{h,cpp}` (`rood_commands`), C++ side; Lua
   `rood.dev.command{id, title, run[, category][, shortcut][, enabled]}` (dev.tools), RPC
   `editor_command {action "list" | "run" | "palette", id, query}`. The palette's fuzzy match is a
   subsequence match scored by word starts and runs (no library).
7. **Data, not constants:** the default layout's fractions and the palette's size are settings keys
   (`editor_shell_left`, `editor_shell_right`, `editor_shell_bottom`, `editor_palette_width`,
   `editor_palette_rows`), shown under Details > Graphics > "Editor shell", set by RPC `graphics`
   (the `editor_keys` table in `dev_rpc.c`) and saved by `pc_settings_write`.

## Tasks

### 1. Shell module and docking on (`pc/src/editor_shell.{h,cpp}`)
- `io.ConfigFlags |= ImGuiConfigFlags_DockingEnable` in `pc_overlay_init`; multi-viewport off.
- `rood_shell::frame(width, height, bar_height, toolbar_height)`: a host window ("##shell") with no
  background, no inputs on its decoration, filling the window below the toolbar; `DockSpace` in it
  (no passthru flag). Returns the dock space id.
- `rood_shell::game_panel()`: `Begin("Game")` (NoBackground, NoMove, NoScrollbar, NoCollapse); its
  content rectangle → `pc_gl_inset` (left, top, right, bottom); the hit-test holes (decision 2). When the
  Game window is hidden (a tab behind another), the inset is the dock node's rectangle so the picture
  keeps its place (`DockNode->Pos/Size`), or the full window when the window is closed.
- Outliner and Details lose `NoMove | NoResize | NoSavedSettings | NoTitleBar` and the forced
  position: they are docked windows now. Existing tabs inside them unchanged.
- Every `visible` frame: `menu_bar`, `toolbar(0, bar, width)`, `rood_shell::frame`, Game, Outliner,
  Details, then the tool windows as today.
- Editor closed: `pc_gl_inset` zeroed (as today). Photo mode's hidden overlay: `visible` false → zero.
- Tests: `editor_shell_smoke.py` sections `dock` (the Game panel's picture rectangle is inside the panel,
  at the game's aspect: RPC `editor_shell` replies the panel and `editor_select` the view), `closed` (F1:
  view rectangle equals the one before the editor opened). Run `editor_selection_smoke` on GL as the
  picking gate for the step.

### 2. Default layout and reset (`rood_shell::reset_layout`)
- DockBuilder: remove the node, add it, split left (Outliner, Library), right (Details), bottom (tool
  windows), centre Game. `DockBuilderDockWindow` for every tool window name (Cutscene, Room Browser,
  Material review, Memory cards, Keyboard shortcuts, Light all fixtures in room, Lua console, Library
  floating) so the bottom node survives ini pruning while closed. Fractions from the settings keys.
- Built on the first frame with no dock node for the id (a fresh ini) or a `[ShellLayout]` version
  change; `Window > Reset layout` and the command `shell.reset_layout` rebuild it.
- Plugin windows (`lua_dev_tools.cpp draw_window`) and the C++ tool windows call
  `rood_shell::dock_tool_window()` before their `Begin`: `SetNextWindowDockID(bottom, FirstUseEver)`.
- Tests: `reset` (move the Outliner's node size through RPC `editor_shell {action "layout"}`? No: open a
  floating tool window, reset, check `editor_shell` reports it docked in the bottom node and the Game
  rectangle back to the default), `plugin` (a `rood.dev.window` from a test plugin docks into the bottom
  node on first open).

### 3. Command registry (`pc/src/editor_commands.{h,cpp}`)
- `rood_commands::add({id, title, category, shortcut, run, enabled})`, `remove(id)`, `list()`,
  `run(id)`, `match(query)` (fuzzy, scored). C++ commands registered by `dev_overlay.cpp` at init: every
  File/Edit/View/Window/Help item, the toolbar's buttons (undo, redo, tools, snapping, view modes), the
  shortcuts (W/E/R, I, L, C, F, H, Ctrl+R, Shift+1), Reset layout, each panel's open/focus.
- Lua: `rood.dev.command{...}` and `rood.dev.remove_command(id)` in `lua_dev_tools.cpp`; dropped with
  the plugin; `run` called under the plugin's call budget.
- RPC `editor_command {action "list" | "run" | "palette" | "query", id, query}`; `palette` opens or
  closes it; the reply lists matches in palette order.
- Tests: `commands` (list has the panels' commands; `run` opens the Room Browser; a Lua command appears
  and runs), `palette` (Ctrl+Shift+P through `editor_input` opens it; typing "room" ranks Room Browser
  first; Enter runs it; Escape closes).

### 4. Command palette (`rood_shell::palette`)
- Ctrl+Shift+P (viewport_keys and editor_shortcuts both allow it; not while typing). A floating window
  over the Game panel's centre (size from `editor_palette_width` em and `editor_palette_rows`), a search
  field with focus, matches with category and shortcut, up/down, Enter runs, Escape closes, click runs.
- Draws after the tool windows (on top). `NoDocking | NoSavedSettings`.

### 5. Window menu and settings
- Window: Game, Outliner, Library, Details, then the tool windows (checkable), plugin windows, Lua console,
  Keyboard shortcuts, Memory cards; a separator, Command palette (Ctrl+Shift+P), Reset layout.
- `rood_shell::parse_setting / write_settings` (project_settings.cpp), `editor_keys` in `dev_rpc.c`,
  a Details > Graphics > "Editor shell" section with the fractions and the palette size.
- `pc/docs/Extensions.md`: `rood.dev.command`, the `editor_command` and `editor_shell` RPCs.

### 6. Gates
- `editor_shell_smoke` (new), `editor_cutaway`, `editor_undo`, `editor_selection`, `editor_schema`,
  `editor_transform`, `editor_handles`, `editor_library`, `editor_snap`, `editor_roomload`,
  `editor_tools_probe`, `photo_foundation`, `photo_mode`, `photo_full_room`, `widescreen_smoke`: GL and
  Vulkan, one at a time, `nice -n 10`.

## Progress

- 2026-10-30 13:15: plan written; builds (64, battle, editor_tools_probe) green in the worktree.
- 2026-10-30 14:05: tasks 1-5 built (58f1ebb71 and this commit): docking on, the Game panel as the
  presenters' inset plus a hit-test hole on the panel, the dock space's host child and the shell
  window (Dear ImGui's `DockSpace` hosts nodes in a child window "##shell/DockSpace_..."), the default
  layout from the settings fractions, Reset layout (tool windows re-docked once per reset),
  `editor_commands` (73 commands registered by dev_overlay.cpp), the palette, `rood.dev.command`,
  RPC `editor_shell` / `editor_command`, Extensions.md. `editor_shell_smoke` passes on GL (48 checks).
  Next: the gates on GL, then Vulkan.
- 2026-10-30 14:10: slice 1 done. Gates green on GL and Vulkan (one suite at a time, nice 10):
  editor_shell (48 checks), editor_selection, editor_handles, editor_library, editor_cutaway,
  editor_undo, editor_schema, editor_transform, editor_snap, editor_roomload, photo_foundation,
  photo_mode, photo_full_room, widescreen_smoke, editor_tools_probe. Also green on both:
  lua_imgui_smoke (its other-window check moved after the retry sequence: the plugin's windows now
  tab into one node, the one behind a tab does not draw), room_browser, material_review,
  cutscene_viewer, cutscene_sequencer, cutscene_freecam, light_actors, fixture_lighting,
  system_settings, ui_system, lua_smoke. Known limits: the Game panel cannot be undocked (the
  picture is drawn under the UI, so a floating Game window would show the panels through it) and
  nothing docks over it as a tab; a tool window behind another's tab does not draw (Dear ImGui).
