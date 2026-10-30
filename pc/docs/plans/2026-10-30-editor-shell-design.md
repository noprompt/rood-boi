# Editor shell: design (slice 1 of the Vagrant Story editor)

Status: approved by the user, 2026-10-30 (mockup reviewed in chat). Built by a Fable worker in worktree `editor-shell`.

## Intent

The user's goal for rood-boi's tools: **what Hammer is to Half-Life, for Vagrant Story** — a general
purpose editor for the game, powerful enough for people to make DLC-sized content, change the difficulty
or do "really crazy stuff", and for artists to experiment with lighting, textures, models and animation.
Everything but the disc is ours, so everything is open to editing. The trigger was another PS2 port's
editor (P3FES, `~/git/C-GBL/P3FES-Decompilation`, its showcase video): one docked window, the game as a
panel, a Hierarchy and an Inspector, a command palette, an event timeline (sequencer) of a scene's beats.
That editor is Dear ImGui too: the polish is structure, not the framework.

The editor must grow **as a shell that existing and coming tools slot into, one finished piece at a
time**, not as one more unfinished thread beside the porting waves, the classic UI in Lua, the
materials tools and the Lua game events. This document designs the shell's first slice; later slices
are listed at the end only so this one leaves room for them.

## What exists (2026-10-30)

- The in-game editor (F1 / Escape; `pc/src/dev_overlay.cpp`, Vulkan's `pc/src/vk_overlay.cpp`), Unreal
  conventions from the artist-tools design (`pc/docs/plans/2026-10-15-artist-tools-design.md`): RMB +
  WASD fly, Alt orbit, MMB pan, F frame, W/E move/rotate; viewport picking; a shared selection model
  (`editor_selection.*`); a property schema (`editor_schema.*`) behind **Details**; the **Outliner**;
  the **Library** (a tab beside the Outliner or one floating window: "not Dear ImGui docking ... a later
  step", that design's decision); undo (`editor_undo.*`); viewport handles.
- Separate windows: Material review, Room Browser, Cutscene, Memory cards, Keyboard shortcuts, Light all
  fixtures in room, Colour popover, the toolbar, and plugin windows (`rood.dev.window`, Extensions.md
  "Developer tool windows").
- The bundled Dear ImGui is 1.93 WIP of the **docking branch**; docking is not enabled. Layout persists
  in `imgui.ini` (`pc/build/boot/imgui.ini`).
- The editor draws over the full-window game picture; picking and handles work in window coordinates.
- Tests: `editor_*_smoke.py` (cutaway, handles, library, roomload, schema, selection, snap, transform,
  undo), `editor_tools_probe`; they drive the editor through RPC, including viewport clicks.

## Goals (slice 1)

1. **Docking on.** One editor workspace while the editor is open: panels dock into a dock space that
   fills the window; tabs, splits and floating panels as Dear ImGui docking gives them. Multi-viewport
   (panels as OS windows) stays off.
2. **The game view is a panel.** While the editor is open the game picture is drawn inside a "Game"
   panel at its own aspect, not under the panels. Everything that works on the picture today works in
   the panel: picking, handles, the camera (RMB fly, Alt orbit, MMB pan, F frame), drag-and-drop from the
   Library, the fit-to-window tool, hints. Input stays as today: with the editor open the keyboard is the
   editor's and the pad plays the game (`pc_overlay_event`); keyboard play inside the panel is not part of
   this slice (my call: it would need rules against W/E/R, I, L, C, F, WASD/QE and Escape). The game's own
   ImGui layers (modern menus, HUD, prompts, option peek, plugin HUD panels) stay attached to the game
   picture, now the panel's. Editor closed (F1): the game fills the window exactly as today.
3. **Existing windows become panels, behaviour unchanged.** Outliner, Details, Library, Material review,
   Room Browser, Cutscene, Memory cards, Keyboard shortcuts, Light all fixtures in room, the toolbar
   (a dock-bar or a panel), and every `rood.dev.window` (plugin panels dock like ours). Popovers stay
   popovers.
4. **A default layout**, and a command to reset to it: Outliner (with the Library tab) left, Game
   centre, Details right, the tool panels (Cutscene, Material review, Room Browser, ...) tabbed at the
   bottom. The user's own layout is saved and restored (ini), per user, not committed.
5. **A command palette** (Ctrl+Shift+P): one registry of named actions; the palette lists and searches
   them and runs one. It is filled with the actions the tools already have (opening each panel, the
   toolbar's buttons, the editor's existing shortcuts and menu items, reset layout). Plugins add their
   own through Lua (`rood.dev.command{...}`, dev.tools capability), so the registry is the one place a
   new tool registers what it can do.
6. **A Window menu** listing every panel (open/close/focus) and Reset layout.

## Non-goals (slice 1)

- A new selection or undo model (both exist; making every tool use them is a later slice).
- Mods as the save target, a start page, projects.
- The event timeline, data tables, any new editing tool.
- Restyling widgets or a new theme beyond what docking needs.
- A separate editor application.

## Anti-goals (a failure even if it works)

- Any existing editor workflow breaks or gets slower: F1/Escape, the camera, shortcuts, picking,
  handles, drag-and-drop, the fit tool, plugin windows, photo mode (its UI and its captures never show
  editor panels), RPC-driven tests.
- The game with the editor closed looks or behaves differently (picture placement, 16:9, input).
- Half-done: panels that only work on one renderer, a game panel that loses picking, a palette with a
  handful of actions. The slice ships complete on **GL and Vulkan** or not at all.
- Look-and-feel values hard-coded (the default layout's proportions, palette size, etc. are data).

## Constraints

- Both renderers' overlays (`dev_overlay.cpp` GL, `vk_overlay.cpp` Vulkan) and their game-picture
  placement; the hardware renderer's picture rectangle is what picking maps through.
- Editor RPCs that take coordinates keep their meaning: **window pixels** (`dev_rpc.c` "mouse: window
  pixels"; `project` returns a world point's window pixel; real SDL mouse events are window pixels too).
  Tests stay layout-independent by going through `project`; the default layout (and any test layout via
  `ROOD_IMGUI_INI`) keeps the Game panel unobstructed (my call).
- Photo mode with the editor open keeps today's behaviour: the overlay hides and the picture is full-window
  (my call).
- The worker brief (`pc/docs/Worker_Brief.md`) holds: worktree, gates, rules. No changes under `src/`
  are expected.
- Plugin API changes are documented in `pc/docs/Extensions.md` (api_version stays 1 unless something
  breaks).

## Left to the builder

- How the game picture gets into the panel on each renderer (render into the panel's rectangle versus a
  texture the panel shows), as long as picture quality, 16:9 and frame pacing are unchanged and the
  picture rectangle stays the single source for picking.
- The palette's look, fuzzy matching, the registry's C++/Lua shape (one registry, both sides).
- Where the toolbar lives in the dock layout.
- Migrating `imgui.ini` (old floating positions may be dropped once; say so in the hand-back).

## Testing

- A new `editor_shell_smoke.py` on GL and Vulkan: the dock space and default layout come up; the Game
  panel's picture rectangle is inside the panel at the game's aspect; a click on a known object in the
  panel selects it (the same object `editor_selection_smoke` picks today); a palette action runs (opens a
  panel); Reset layout restores the default; a plugin `rood.dev.window` docks; F1 closes the editor and the
  game fills the window again (picture rectangle as before the editor opened).
- Every existing `editor_*` smoke, `editor_tools_probe`, `photo_*` and `widescreen_smoke` pass on GL and
  Vulkan unchanged (or with layout-independent coordinate updates, explained).

## Later slices (not designed here)

Shared selection and undo across every tool; mods as the save target, a start page and projects; the
event timeline (a scene's event script as tracks, scrubbable while it plays; it builds on the Lua game
events work, `2026-10-30-lua-game-events-survey.md`); data tables; asset inspectors (materials' click
to inspect, models, animations); watch pins and value ranges in the Inspector.
