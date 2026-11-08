# PS1 ties

A map of every way the running game is still shaped like a PlayStation. It is for deciding what to
replace next, and in what order.

Written 2026-11-08 from the code at that commit, by reading it (nothing was built or run). Where an
older document disagrees with the code, the code is trusted and the disagreement is listed in
"Where the docs are out of date" at the end. Anything inferred but not confirmed in code is marked
**unconfirmed**. Sizes are rough judgments in agent time, not measurements:
small (about a day), medium (a few days), large (a week or more), very large (weeks, and it touches
most of the game).

## The short version

The game's logic is native x86-64 code, and no MIPS code runs. But it is still a PS1 program that has
been given a fake PS1 to run on. It keeps a 2 MB "RAM" at the PS1's own addresses and builds its
pictures as GPU command packets in that RAM. It stops at every vertical blank to hand control to the
host, and it reads its disc by sector number. It talks to the sound chip through chip registers, and it
sees the controller as a PS1 pad. The host (renderer, audio, input, tools) is modern and sits around
this core. The core itself is the part that still behaves like an emulator.

Two things decide how "emulator-like" it feels:

1. **The game's own frame loop is the clock.** Logic, drawing, audio and input all advance inside the
   game's call to `VSync`, on one thread, at the PS1's 59.94 Hz field rate. The game updates its world
   every 2 fields (about 30 per second), sometimes 4. Everything smoother than that is the host
   inventing in-between pictures.
2. **The picture is still described in PS1 terms.** Even where the renderer draws real 3D models, the
   game still produces packets and ordering tables, and textures still live in a 1024 x 512 16-bit
   "VRAM".

## Summary table

"Feels" is what the player can notice today. Status: **PS1** (fully PS1-shaped), **partly** (a native
path exists next to the PS1 one), **native**.

| ID | Tie | Player feels | Status | Size to replace | Depends on |
|---|---|---|---|---|---|
| T1 | The game's loop blocks in `VSync`; host work runs inside it, on one thread | Frame hitches stall sound and input; no unlocked frame rate | PS1 | very large | T4, T7, T13 |
| T2 | Logic runs at 30 or 20 per second; the host interpolates some things | Characters smooth, HUD, menus and many effects step at 30 | partly | large | T1, T4 |
| T3 | Wall-clock time read as PS1 "scanlines" | Done 2026-11-08 | native | done | none |
| T4 | GPU packets and ordering tables built in RAM, then walked | Draw order and effects follow PS1 rules; widescreen and 2D compromises | partly | very large | T13, T14 |
| T5 | Textures and palettes live in a 1024 x 512 16-bit VRAM; a CPU rasterizer still runs | Texture size, 256-colour limits, palette animation | partly | large | T4 |
| T6 | 320 x 224 display area, never-cleared frame buffer, 4:3 assumptions | Widescreen is a set of fixes on a 4:3 game | partly | large | T4, T7 |
| T7 | The GTE (3D maths coprocessor) as a global register state machine | Nothing directly | partly | very large | none (but blocks T1) |
| T8 | 2D, text and effects drawn as packets (the classic UI, most effect plugins) | Original look; steps at 30; no real hi-res UI unless the modern layer is on | partly | very large | T4, T5 |
| T9 | Disc read by sector number from a raw disc image, through the PS1 load queue | "NOW LOADING" and load times of the original design; needs the user's disc image | PS1 | large | T10, T12 |
| T10 | Overlays: fixed RAM slots, statics reset on load, entry by long jump | Nothing directly (loading screens exist because of it) | PS1 | large | T9, T12 |
| T11 | The build still links the PS1 symbol map and reads the original executable | Nothing directly | PS1 | large | T13, T15 |
| T12 | 2 MB fixed RAM at `0x80000000`, a 970 KB game heap, a stack below 2 GB | Hard limits; nothing can grow | PS1 | very large | T13 |
| T13 | 4-byte "guest pointers" and PS1-layout structs | Nothing directly | PS1 | very large | none |
| T14 | The 1 KB scratchpad used as shared game memory | Nothing directly | PS1 | large | T13 |
| T15 | Globals at PS1 addresses; code named after addresses; raw memory in Zig | Nothing directly | PS1 | very large | T13 |
| T16 | The SDK/BIOS layer is hand-written and covers only what this game calls | Nothing directly (crashes with a message on anything uncovered) | partly | medium | T9, T20 |
| T17 | Save states, rewind and the RPC depend on the memory layout | Nothing directly | PS1 | follows T12, T13 | T12, T13 |
| T18 | Sound: the PS1 sound driver writes chip registers; a software SPU renders them | Sound is the PS1's, locked to the game thread | partly | large | T9, T1 |
| T19 | CD-XA audio decoded from the disc's sectors | Nothing directly | PS1 | medium | T9 |
| T20 | Controller seen as a 16-button digital pad, one read per field | No analog movement; input latency of the game's frame rate | partly | small | T1 for latency |
| T21 | Movies: PS1 STR video decoded by a software MDEC, from disc | 15-year-old video quality | PS1 | medium | T9 |
| T22 | Saves through the BIOS memory-card calls into 128 KB card images | Saves look like memory cards (and move between emulators) | PS1 | medium | T13 |
| T23 | Threading: the game, the renderer's CPU side, the SPU and the RPC share one thread | Anything slow anywhere costs a game frame | PS1 | part of T1 | T1, T7 |

## T1. The game's loop blocks in `VSync`; the host runs inside it

**What it is.** The game is a PS1-style program that loops forever and calls `VSync(n)` to wait for the
next vertical blank. On the PC, `VSync` does not wait: it runs a whole host "tick" (RPC commands,
plugins, window events and pacing, CD, audio, drawing the picture) and then returns to the game. The
game runs on its own stack, switched to at startup, and the host is the code above `pc_vsync_boundary`
on that stack.

**Player feels.** Frame time is game work plus host work in series, so anything slow in the host (a
shader hitch, a heavy lighting frame) delays the game's next logic step, the sound driver and input
reads together. There is no way to run the display faster than the game's own frame rate except by
re-presenting an old frame with interpolation (T2).

**Evidence.**
- `pc/src/boot_sdk.c`: `VSync`, `pc_vblank_wait` (calls `pc_vsync_boundary` or `pc_tick`, then fills the
  pad buffer, then runs the game's VSync callback).
- `pc/src/boot_runtime.c`: `pc_tick`, `tick_frame_work` (RPC, plugins, `pc_window_tick`, `pc_cd_tick`,
  `pc_audio_frame`, then `pc_window_frame`), `run_game_on_low_stack`.
- `pc/src/snapshot.c` header: describes "the game's frames below, the host's above" the vsync boundary.
- `pc/src/game/SLUS_010.40/main.c`: `vs_main_gametimeUpdate` calls `VSync`; `_diskInitRead` and the CD
  queue are polled from the same call.

**Status.** Fully PS1-shaped. Native only in that the loop runs as plain C.

**To replace.** Very large. The game would have to hand a finished frame description to a separate
renderer and keep running. That needs the frame's contents to be a value (T4, T7) and the host's reads
of game state to be safe off the game thread (T13, T17).

**Depends on.** T4 and T7 first (nothing else owns a frame's worth of data); T13 for safe sharing.

## T2. Logic rate, and what the host fills in

**What it is.** The game advances its world once per "game frame", every 2 vsyncs normally, 4 in some
scenes (`vs_gametime_tickspeed`). The host presents once per vsync and, if `pc_hw_interpolate` is on
(it is, by default), draws in-between pictures from the previous and current game frames. It can present
`pc_present_rate` images per vsync (default 1, up to 8, or "match display").

The pacing is the host sleeping until absolute 59.94 Hz deadlines (`FIELD_NS`), whether or not display
sync is on. The interpolation phase is an integer fraction of that field (`k/n`), not real elapsed time.

**Player feels.** Characters, weapons, props, drop shadows, particles and the camera are blended, so
they look smooth. What is still drawn as packets steps at the game's rate: the HUD, menus, text, the
screen-space effect plugins, particles on fixed layers, texture animation and vertex morphs
(`pc/docs/Native_Rendering.md`, "What still steps"). On displays whose refresh is not a whole multiple of
59.94 Hz, the fixed fractions cannot match the display clock; the cadence consequence is
**unconfirmed**.

**Evidence.**
- `pc/src/boot_window.c`: `pc_window_tick` (deadline pacing), `pc_window_wait_fraction`,
  `pc_window_present_rate`, `display_rate`.
- `pc/src/boot_runtime.c`: `tick_frame_work` (the extra presents at fractions).
- `pc/src/gpu_hw.c`: `pc_hw_interpolate = 1`, `pc_present_rate = 1`.
- `pc/docs/Native_Rendering.md`, "Animation in-betweens": the animation system has no fractional time;
  characters change once per game frame.

**Status.** Partly native: the in-betweens are real, but the simulation underneath is PS1-rate and the
host's presentation clock is derived from it.

**To replace.** Large for a true unlocked frame rate: present on the display's clock, from real time
since a frame arrived, with a vsync-aware swap (the doc's own list; `Native_Rendering.md` end). A higher
simulation rate would be much larger, because the game's logic counts ticks (animation, AI, timers) and
nothing here makes them fractional.

**Depends on.** T1 (to present independently of the game's loop) and T4 (to know what is a drawable
object versus a packet that cannot be interpolated).

## T3. Wall-clock time read as PS1 scanlines

**Done 2026-11-08.** The game's elapsed-scanline read (`VSync(1)`, `func_800E45B4`) is a fixed step per read from
each vblank (`scanlines_now` in `pc/src/boot_runtime.c`), never the host's clock, so how much the AI does in a frame
no longer depends on how fast the machine is that frame.

## T4. GPU packets and ordering tables

**What it is.** The game builds drawing commands as PS1 GPU packets (polygons, sprites, lines, copies)
in RAM, links them into an ordering table (a linked list bucketed by depth, whose bucket order is the
draw order), and calls `DrawOTag`. The host walks the list in `pc_draw_packet` on the game thread.
Links are 24-bit guest addresses.

Native drawing sits beside this. The room, characters, weapons, props, drop shadows and some particles
are drawn from native meshes (`render.c` lists). They are "placed" in the table by marker packets,
so they keep the PS1's draw order against packets still coming from the game. The game keeps building the
packets for most of them too; the renderer skips what native draws cover.

**Player feels.** Draw order, blending and effect behaviour follow PS1 rules because they are the PS1
rules. Anything the game draws as packets cannot be re-lit, re-textured or interpolated without
special-casing. Widescreen is done by narrowing projection and anchoring packets to screen edges
(T6).

**Evidence.**
- `pc/src/boot_sdk.c`: `DrawOTag`, `DrawPrim`, `ClearOTag`, `ClearOTagR`.
- `pc/src/boot_runtime.c`: `pc_draw_packet`, `next_packet` (OT links; the 4-byte-pointer branch is dead on
  64-bit), the marker checks (`render_is_marker`, `render_translucent_marker`).
- `pc/src/render.c`: `pc_native_room = 2`, `pc_native_actors = 2`, `pc_native_blend`, `pc_native_objects`,
  `pc_native_shadows`, `pc_native_effects` (all on); `pc_reconstruct = 0`.
- `pc/src/gpu_hw.c`: `pc_hw_begin_ot`, `pc_hw_native_marker`, `pc_hw_effect_packets`.
- `pc/docs/Native_Rendering.md`; `pc/docs/Vulkan_Renderer.md` (Vulkan is the default renderer; OpenGL
  is frozen as a fallback).

**Status.** Partly native. Room, characters and drop shadows are native; screen-space geometry,
the effect plugins, most 2D and all text under the classic UI are packets.

**To replace.** Very large. The code that writes packets is spread through every overlay
(`pc/src/game/BATTLE`, `EFFECT`, `MENU`, `TITLE`, `ENDING`, the packet macros in the shared headers).
Each user must emit typed draw items with explicit sort keys instead. The room and character path shows
the pattern; the remaining work is the long tail. The doc `Native_Rendering.md` lists the effect
plugins as not done.

**Depends on.** T13 and T14 (packets are built through guest pointers and a scratchpad cursor).

## T5. VRAM: the texture and palette store, and the CPU rasterizer

**What it is.** All textures, palettes (CLUTs) and frame buffers live in a 1024 x 512 array of 16-bit
pixels. The game loads images into it with `LoadImage`, animates palettes by overwriting rows of it, and
reads it back with `StoreImage`. A software rasterizer in `boot_runtime.c` still draws into this array
as the reference, and the GPU path mirrors it into an R16UI texture so shaders decode 4-bit, 8-bit and
15-bit texels the way the PS1 does. When native draws cover an area, the CPU rasterizer skips it and
"stale" areas are copied back from the GPU only if the game reads them.

Tools key on this too: material maps are named by a hash of the texels under a texture's UV box, found
in VRAM (`pc/docs/Materials.md`).

**Player feels.** Texture resolution and colour limits are the PS1's; palette flicker and palette-swap
effects work by writing the VRAM array. Menus that read the screen back (a text box over the frame) can
force a GPU-to-CPU copy.

**Evidence.**
- `pc/src/boot_runtime.c`: `vram`, `pc_vram_transfer`, `pixel`, `texture`, the CPU rasterizer.
- `pc/src/gpu_hw.c`: the header comment, `pc_hw_sync`, `pc_hw_raster_skip`, `pc_hw_stale_copy`.
- `pc/src/vk_hw.c`: native VRAM as `R16_UINT`.
- `pc/docs/Native_Rendering.md`, "Without reference packets".

**Status.** Partly native: the display image is native (scaled, lit, post-processed), but its inputs are
still VRAM pixels and the CPU copy of VRAM is still kept exact.

**To replace.** Large. Native textures and palettes as assets (decoded once, keyed by asset id, palette
animation as data) would remove both the VRAM array and the CPU rasterizer. That means every
`LoadImage` caller (and the texture-page and CLUT fields in every packet and native mesh) naming an asset
rather than a VRAM position.

**Depends on.** T4 (packets name texture pages and CLUTs by VRAM position).

## T6. Display area, frame buffer and 4:3 assumptions

**What it is.** The game sets a display area (typically 320 x 224) with `PutDispEnv` and `PutDrawEnv`,
and alternates frame buffers inside VRAM. It never clears the buffer, so stale pixels from older frames
show wherever nothing is drawn (the plan notes the free camera fights this). It culls and
projects for a 4:3 view. 16:9 is done by narrowing the GTE's projected X to 3/4 about the centre,
compressing 2D the same way in the rasterizer, and re-anchoring packets that hug an edge. Several kinds
of 2D (damage numbers, labels, the map's icons) need special handling so they are not narrowed twice.

**Player feels.** Widescreen works but is a stack of corrections; anything the game culls
to its 4:3 view cannot appear at the edges of a wider one (**unconfirmed** case by case). Cutaway
and screen-sized pictures are scaled or anchored rather than redrawn for the wider shape.

**Evidence.**
- `pc/src/boot_runtime.c`: `pc_display_env`, `pc_draw_env`, `pc_display_size`.
- `pc/src/boot_sdk.c`: `PutDispEnv`, `SetDispMask`, `ClearImage`.
- `pc/src/widescreen.h`: the hooks (`pc_gte_anchored`, `PC_ANCHOR_*`, `pc_hw_anchor_packets`).
- `pc/docs/Modernization_Plan.md`, opening section (the free camera and the never-cleared screen).

**Status.** Partly native.

**To replace.** Large. A view that is described as a camera and a viewport, with the game's culling driven
by that camera, is the real fix. It rides on T4 and T7.

**Depends on.** T4, T7.

## T7. The GTE as a global register machine

**What it is.** The PS1's 3D coprocessor is run as a software library (PsyCross's GTE, MIT) with the
registers as one global state. Game code loads vertices, runs an operation, and stores results through
macros (`gte_ldv0`, `gte_rtps`, `gte_nclip` and so on). Battle's Zig code does the same through
`game/common/gte.zig`, which calls the same functions in the same order. Results must keep the GTE's
fixed-point rounding and flags, because some game logic and the renderer's culling and ordering depend
on them.

**Player feels.** Nothing directly.

**Evidence.**
- `pc/third_party/psycross/src/gte` and its `ROOD-NOTES.md`; `pc/include/inline_c.h`.
- `game/common/gte.zig` ("the registers are host state").
- Hand-written GTE routines: `pc/src/battle_gte.c`.
- A text count (by grep, 2026-11-08) of `gte_*(` uses: 432 in `pc/src/game`, 11 in the Zig sources.
- Widescreen reads and changes GTE results (`pc/src/widescreen.h`).

**Status.** Partly native: the arithmetic is native, the interface is the PS1's.

**To replace.** Very large in total, because the uses are scattered through BATTLE, EFFECT and ENDING.
It can be done in pieces: each user switches to explicit input and output values, while the old state
machine remains for the rest. Float maths must not be substituted blindly (rounding is relied on).

**Depends on.** Nothing, but it must go before any renderer thread (T1), since the global state is
single-owner.

## T8. 2D, text and effects as packets

**What it is.** The classic HUD, menus, text, loading screens, and most of the effect plugins in
`pc/src/game/EFFECT` and `GIM` are drawn as 2D packets from VRAM sprites and glyphs. The host has
replacements layered on top: `ui_text.c` (glyphs from fonts), `ui_bubbles.c`, `button_prompts.c`,
`ui_upscale.c` (texture magnification), and the modern menus and HUD (`pc/src/ui`, `pc/src/hud`,
`pc/docs/Modern_Menus.md`). With the modern UI off, the game's own sprites and layout are kept on
purpose; only typography is upgraded.

**Player feels.** The original look, at the original update rate, magnified. Menus run on game
frames (steps at 30). The modern menus, where available, are real native UI but read their state out of
PS1-layout structs (T13).

**Evidence.**
- `pc/src/gpu_hw.c` and `pc/src/ui_text.c` (glyph replacement from the packets' code),
  `pc/src/ui_upscale.c`.
- `pc/src/ui/*_bridge.c` (modern menu bridges), `pc/src/hud/*_bridge.c`.
- `pc/src/project_settings.cpp`: `pc_ui_menus` has a static default of 0 here; whether a shipped
  settings file turns it on is **unconfirmed**.
- `pc/docs/Native_Rendering.md`: "Left on packets: the effect renderers ... 2D UI, menus and movies".

**Status.** Partly native.

**To replace.** Very large, but incremental by screen (the modern menu phases show the pace). The effect
plugins are the least explored: the doc says no spell could be cast over RPC to test them.

**Depends on.** T4, T5.

## T9. Disc reads by sector number

**What it is.** The game names every file by its disc position (a sector number, `VS_*_LBA` constants in
`pc/src/game/include/lbaMacros.h`) and loads it through a small asynchronous queue (32 slots, with
priorities and frame countdowns) that the game polls every frame. On the PC the actual read is
synchronous from a raw 2352-byte-sector disc image the user supplies; the queue's states still run so
the game's own logic keeps its timing.

The same disc image is opened by other code: overlay statics (T10), the CD drive for movies and XA
audio (T19, T21), the room catalog tool, and the item name reader.

**Player feels.** The original loading structure ("NOW LOADING", loads at room and menu changes). It
needs the user's disc image at runtime; there is no extracted-file mode.

**Evidence.**
- `pc/src/boot_runtime.c`: `pc_disc_read`.
- `pc/src/game/SLUS_010.40/main.c`: `_diskInitRead` (the PC branch under `ROOD_PC_BOOT_DIAGNOSTIC`, a
  define the PC build always passes: `pc/tools/build_boot.py`), `_processCdQueue`,
  `vs_main_diskLoadFile`, `pc_cd_queue_load`.
- `pc/src/overlay_statics.c`, `pc/src/cd_drive.c`, `pc/src/room_catalog.c`, `pc/src/ui/item_names.c`
  each open the image by name.
- A count (by grep, 2026-11-08): 566 distinct `VS_*_LBA` constants referenced in `pc/src/game` C files.

**Status.** Fully PS1-shaped.

**To replace.** Large. Files named by asset id, loaded by a loader that owns the timing, with the data
formats the game parses unchanged at first. The game's wait-for-loaded loops and the 32-slot queue are
game logic, so removing them is a code change per overlay, not a swap.

**Depends on.** T10, T12 (loaded data is placed into fixed RAM slots and the fixed heap).

## T10. Overlays: fixed slots, restarted statics, long-jump entry

**What it is.** The game is split into overlays that load into fixed RAM addresses: the title, the main
menu, effect plugins and the submenus (each family shares a slot), and BATTLE and ENDING (share another).
The code is compiled in permanently, but the loaded file's bytes still land in RAM as data and
the game reads its tables from there. Because on a PS1 reloading a file resets its variables, the host
snapshots each overlay's initial statics and restores them whenever that file is read
(`pc_overlay_statics_loaded`). Moving between title and battle uses saved jump points
(`__builtin_longjmp`) that replace the PS1's stack reset.

**Player feels.** Nothing directly. This is why menus and effects behave as if reloaded each time.

**Evidence.**
- `pc/src/overlay_statics.c`: `pc_overlay_statics_init`, `pc_overlay_statics_loaded`.
- `pc/tools/build_boot.py`: sections renamed per overlay file; the slot addresses in the source-list
  comments (`0x800F9800`, `0x80102800`, `0x80068800`).
- `pc/src/boot_sdk.c`: `vs_overlay_jumpToTitle`, `vs_overlay_jumpToBattle`, `pc_title_jump`,
  `pc_battle_jump`.

**Status.** Fully PS1-shaped; the code part is native.

**To replace.** Large. Overlays become modules with explicit init/reset state; the restart rule becomes
code instead of a memory copy. The effect plugins that reuse function names at one address are the
awkward part.

**Depends on.** T9 and T12.

## T11. The build is tied to the original binaries

**What it is.** The PC build still links the original program's symbol map to learn every global's PS1
address (`main-symbols.elf` and one per overlay, linked with a MIPS linker from the decompilation's
build tree). It also reads the original executable and overlay files to check and generate function
tables, and to size data regions. The original executable is loaded into the fake RAM at startup; it
supplies the game's initial data.

**Player feels.** Nothing directly. It means the game cannot be built, or run, without the original
data and the decompilation's build products.

**Evidence.**
- `pc/tools/build_boot.py`: `link_symbols`, the function-table check ("differs from the overlay"),
  the LP64 import conversion.
- `pc/src/boot_runtime.c`: `main` loads the executable's image into RAM.
- `pc/src/game/README.md`: a fresh clone's setup still extracts game data with the top-level tools.

**Status.** Fully PS1-shaped. How much of the build still depends on the MIPS toolchain is
**unconfirmed** without building.

**To replace.** Large. Replace each address-derived table with data the project owns, which follows
T15 and T13.

**Depends on.** T13, T15.

## T12. Fixed RAM, a fixed heap, a stack below 2 GB

**What it is.** The host maps 2 MB at `0x80000000` (RAM), 1 KB scratchpad at `0x1F800000` and an I/O
page that holds sound chip registers. The original executable and overlays load into it. The game's
own heap is a free-list allocator inside that RAM, initialised at `0x8010C000` with `0xF2000` bytes
(about 970 KB) in the main program, BATTLE's initialiser and ENDING. The game runs on a 64 MB stack
mapped at a fixed address below 2 GB so pointers to locals fit in 4 bytes.

**Player feels.** Hard budgets: anything that does not fit the PS1's memory cannot exist, which limits
what content the game can hold.

**Evidence.**
- `pc/src/boot_runtime.c`: `main` (`map_guest(0x80000000, 0x200000)`), `reserve_game_stack`
  (`GAME_STACK_BASE`), `run_game_on_low_stack`.
- `pc/src/game/SLUS_010.40/main.c` line near `vs_main_initHeap((vs_main_HeapHeader*)0x8010C000,
  0xF2000)` and the same call in `BATTLE/INITBTL.PRG/18.c` and `ENDING/ENDING.PRG/D4.c`.
- `pc/src/memory.c` / `memory.h` (`rood_memory_span`) is **not** the running memory model. Only a unit
  test (`pc/tests/memory_probe.c`) uses it.

**Status.** Fully PS1-shaped.

**To replace.** Very large. The heap and the fixed addresses go away only when objects stop holding
guest pointers (T13) and the overlays stop assuming slot addresses (T10).

**Depends on.** T13.

## T13. Four-byte guest pointers and PS1-layout structs

**What it is.** Structs that overlay PS1 data (loaded files, the scratchpad, saves, the packet formats)
keep their 4-byte-pointer layout. Pointer members are declared `psx_ptr(T)` and read and written with
`psx_get` and `psx_set`, so structs keep the PS1 size and field offsets on a 64-bit build. A pointer to
host memory above 4 GB is fatal (`pc_psx_bad_pointer`). Structs that the game builds itself were
changed to native layout.

**Player feels.** Nothing directly.

**Evidence.**
- `pc/src/psx_types.h`.
- `pc/tools/ps1_address_baseline.json` (also `pc/tools/ps1_address_lint.py`, which keeps these
  numbers from rising): `guest_pointer_field` 282, `guest_pointer_access` 2921,
  `address_as_integer` 606.
- `pc/src/psx_sdk_layout.c`: compile-time size and offset checks on the SDK structs.
- `game/common/psx.zig`: the same idea for Zig (`Ptr`, `addr`).

**Status.** Fully PS1-shaped by design: it is how the 64-bit port kept the data files valid.

**To replace.** Very large. One struct at a time, once its data has an owned file format and no other
code overlays it. The lint count is the progress meter.

**Depends on.** Nothing, but it gates T12, T14, T15 and T17.

## T14. The scratchpad as shared game memory

**What it is.** The PS1 has 1 KB of fast memory. The game uses it as shared scratch state: the
current packet cursor and ordering table base, per-actor AI state tables, camera and matrix scratch,
accessed as raw addresses (`0x1F80xxxx`) or by `getScratchAddr`. On the PC this is a real page mapped at
the same address.

**Player feels.** Nothing directly.

**Evidence.**
- Baseline `scratchpad` count: 1020. By file (grep of the lint's hits): `pc/src/game/BATTLE` 351,
  `game/battle` (Zig) 258, `pc/src/game/MENU` 114, `pc/src/game/EFFECT` 47, `pc/src/game/ENDING` 29,
  `pc/src/scene_submit.inc` 19.
- `pc/src/game/include/scratch.h` (`vs_scratch_t`); `pc/src/boot_runtime.c` maps the page.
- Example of an unnamed shared slot: the AI loops write `*(int*)0x1F8003FC` and index
  `0x1F80037C` by actor id (`BATTLE/BATTLE.PRG/6FC00.c`, `71618.c`).

**Status.** Fully PS1-shaped.

**To replace.** Large. Each slot becomes a named, typed field in an owned struct. The AI state table is
the biggest and the one tied to behaviour.

**Depends on.** T13.

## T15. Globals at PS1 addresses, address-named code, raw memory in Zig

**What it is.** A large part of the game's data is defined by address: the build gives each global the
address it had on the PS1 (`imports.ld`), so tables and structs the original data refers to line up.
About 100 hard-coded PS1 addresses remain in code. Most functions and globals still carry their address as
their name (`func_800B3CF0`, `D_800F45E0`), a naming fact, not a runtime tie, but it makes the map from
code to behaviour hard to read. Battle's logic is in Zig (1811 `.zig` files under `game/`, 51 subsystems
in `game/ownership.toml`, each function keyed by its PS1 address) and reaches game memory through raw
accessors.

**Player feels.** Nothing directly.

**Evidence.**
- Baseline counts (`pc/tools/ps1_address_baseline.json`): `ps1_address` 100, `scratchpad` 1020,
  `unnamed_symbol` 28365, `zig_raw_memory` 1433 (1309 of them in `game/battle`).
- `pc/tools/build_boot.py` (`imports.ld`); `game/ownership.toml`; `game/common/psx.zig`.
- The LP64 audit counted 941 data imports at its date (2026-10-09); the current figure is
  **unconfirmed** (needs a build).

**Status.** Fully PS1-shaped in addressing; native in logic.

**To replace.** Very large, mostly mechanical per unit: rename by meaning, replace the address with a
typed global, and remove the raw access.

**Depends on.** T13.

## T16. The SDK and BIOS layer

**What it is.** The original program calls Sony's library (GPU, GTE, CD, sound, pad, memory card) and
the BIOS (events, interrupts, root counters). The PC build keeps the game's calling code but supplies
the hardware side itself: `boot_sdk.c` (draw and display calls, pad calls, events, the single
critical-section flag, `rand`), `cd_drive.c`, `audio_libspu.c`, `memory_card.c`, `mdec.c`, and the
PsyCross GTE. The events and root counters cover only what this game uses; anything else stops with
`pc_unimplemented` and a message. The hand-written MIPS assembly of the original was translated by
hand into C and Zig in `pc/src` and `game/` (for example `battle_gte.c`, `battle_movement.c`,
`actor_*.c`); 97 `INCLUDE_ASM` lines remain in `pc/src/game` as markers for functions that the PC build
replaces (a grep count, includes conditional ones).

**Player feels.** Nothing directly; an uncovered call is a crash with a message (`pc_unimplemented`;
`pc/docs/Unimplemented_Paths.md` lists the sites).

**Status.** Partly native: native behaviour behind PS1 call shapes.

**To replace.** Medium per library. Each replacement is the removal of one family of tie
(T9, T18, T20, T21, T22).

**Evidence.** `pc/src/boot_sdk.c`, `pc/src/cd_drive.c`, `pc/src/audio_libspu.c`, `pc/src/memory_card.c`,
`pc/src/mdec.c`, `pc/docs/Unimplemented_Paths.md`, `pc/ASSEMBLY_INVENTORY.md`.

**Depends on.** T9, T20 (and the others per library).

## T17. Save states, rewind and tools depend on the memory layout

**What it is.** The host features that make this port easy to work on, namely save states, rewind, the
state diff, the RPC and the field mapper, treat the game's state as its memory image plus its native
statics plus the game's call stack, pinned at fixed addresses so a snapshot resumes in a new process.
They work because T12 and T13 hold.

**Player feels.** Nothing directly. It is a cost: changing the memory model needs these features
reworked, or they stop working.

**Evidence.** `pc/src/snapshot.c` (header comment), `pc/src/state_rewind.c`, `pc/src/state_diff.c`,
`pc/tools/snapshot_layout.py`, `pc/tools/field_map.py`.

**Status.** Fully PS1-shaped (by design, and dependent on x86 Linux and 64-bit Windows).

**To replace.** Follows T12 and T13; large once those move, because owned state needs a serialization
format.

**Depends on.** T12, T13.

## T18. Sound: register writes and a software SPU

**What it is.** The game's own sound driver (the PS1's sequencer, compiled natively) writes the
sound chip's voice registers into a plain page at `0x1F801C00` and uploads samples (PS1 ADPCM) into a
512 KB sound memory. The host synchronizes those registers into a software SPU
(`pc/third_party/psycross-audio`, whose reverb and noise were rewritten clean-room) and renders it.
The driver's 240 Hz tick is run four times per field, on the game thread, with the
sound render for each quarter after it. Output goes through a ring buffer to an SDL audio device on
another thread.

**Player feels.** The PS1's instruments, reverb and sequencing. Because the driver and the render
run on the game thread, a long frame can starve the ring buffer; the code waits for it to refill rather
than padding silence. (How often that is audible is **unconfirmed**.)

**Evidence.**
- `pc/src/audio_libspu.c`: `pc_audio_frame` (the four ticks), `SpuSetIRQ`, `GetRCnt`.
- `pc/src/audio_spu.cpp`: the register page and `pc_spu_sync_registers`, `pc_spu_render`.
- `pc/src/audio_output.c`: the ring and the device thread.
- `pc/src/game/include/hw.h`, `sound.h`.

**Status.** Partly native.

**To replace.** Large. Replacing the sample format and the voice model while keeping the sequencing is a
mixer project, and the driver is original code that calls the chip directly. A moderate version moves
the mixing off the game thread.

**Depends on.** T9 (samples load from disc), T1 (to leave the game thread).

## T19. CD-XA audio

**What it is.** Streamed audio (movie sound and any XA streams) is stored as ADPCM sectors and played by
the drive without the CPU. The host's drive (`cd_drive.c`) delivers sectors from the vsync tick at the
disc's rate; `xa_audio.c` decodes them, resamples to 44.1 kHz and feeds the software SPU's CD input.

**Player feels.** Nothing directly.

**Evidence.** `pc/src/cd_drive.c` (`pc_cd_tick`), `pc/src/xa_audio.c`.

**Status.** Fully PS1-shaped. What else uses XA besides movie sound is **unconfirmed**.

**To replace.** Medium: convert once to a modern codec at build time, and play it through the host mixer.

**Depends on.** T9.

## T20. The controller as a digital pad

**What it is.** Each field the host puts the pressed buttons into the pad buffer in the PS1's digital
pad format (`pc_vblank_wait`: `0x41`, then the inverted 16 buttons). The game reads that buffer at its own
rate. Sticks, triggers and the keyboard are mapped onto the 16 digital buttons by the host.
The right stick and the photo mode are host features that do not go through the game's pad.
`PadSetAct` (vibration) is a no-op. Whether the original game ever uses it is **unconfirmed**; its title
screen does have a vibration setting.

**Player feels.** Digital movement only (as the original); input is read once per field and acted on at the
game's frame, so input can land up to a game frame late (**unconfirmed**; not measured).

**Evidence.** `pc/src/boot_sdk.c` (`PadInitDirect`, `PadGetState`, `PadSetAct`, `pc_vblank_wait`),
`pc/src/boot_window.c` (`pc_window_buttons`), `pc/src/boot_gamepad.c`, `pc/src/input_record.c`.

**Status.** Partly native (host input, camera and photo controls are native).

**To replace.** Small to give the game an analog stick and rumble; the game's movement code reads
buttons, so analog movement needs game logic changes. Medium for lower latency (needs T1).

**Depends on.** T1 for latency.

## T21. Movies

**What it is.** The intro movie (and any other) is PS1 STR video: the host's drive streams its sectors,
the game's code decodes the Huffman stream (a hand translation of the PS1 routine) and a software MDEC
turns it into pixels in VRAM, in 24-bit mode, which the display shows.

**Player feels.** The original video, at its original quality and frame rate (**unconfirmed** that there is
no upscale or replacement).

**Evidence.** `pc/src/mdec.c`, `pc/src/cd_drive.c`, `pc/src/game/TITLE/TITLE.PRG/22C.c` (`_playMovie`),
`pc/src/boot_runtime.c` (`pc_skip_movies`).

**Status.** Fully PS1-shaped.

**To replace.** Medium: re-encode the movies offline, play them through a host video path, and keep the
game's wait-for-end logic with a simple end signal.

**Depends on.** T9.

## T22. Saves through memory cards

**What it is.** The game saves by calling the BIOS card functions (`bu00:`, `bu10:`). The host serves
them from 128 KB card image files, in the PS1 layout (and several emulator container formats), so saves
can move between this port and emulators. Every card operation completes at once.

**Player feels.** The game's own card screens and slots. Saves are portable to emulators.

**Evidence.** `pc/src/memory_card.c`.

**Status.** Fully PS1-shaped; native I/O.

**To replace.** Medium: a native save file with the same fields, plus an importer and exporter for card
images if portability should stay. The game's save and load screens would be talking to something other
than a card, which touches the card UI code.

**Depends on.** T13 (the save structures are PS1-layout).

## T23. Threading

**What it is.** The game, the host's CPU-side rendering, the CPU rasterizer and packet walk, the
sound driver and software SPU, the RPC, the plugin scripts and window events all run on the main
thread in turn. Other threads are only: the audio device's callback (drains the ring), shader compile
jobs, and some background tool jobs (light suggestion, atmosphere, fixture editing). The GPU works
asynchronously (two frames in flight on Vulkan).

**Player feels.** Anything slow in one place costs a game frame. Moving rendering off the game thread is
how the display clock and the game clock would separate.

**Evidence.** `pc/src/boot_runtime.c` (`tick_frame_work`), `pc/src/audio_output.c` (ring and mutex),
`pc/src/shader_reload.cpp`, `pc/src/lights.cpp`, `pc/src/atmosphere.cpp`, `pc/src/fixture_editor.cpp`
(each starts a worker), `pc/docs/Vulkan_Renderer.md` ("two frames in flight").

**Status.** Fully PS1-shaped by default.

**To replace.** Part of T1.

**Depends on.** T1, T7.

## Dependency picture

```
 T13 guest pointers & PS1 layouts ──┬─> T12 fixed RAM / heap / stack ──┬─> T17 save states & tools
 T15 addresses & names              │                                  │
 T14 scratchpad                     ├─> T10 overlays ──> T9 disc reads ├─> T11 build ties
                                    │                    │              │
 T7 GTE state ──┐                   │                    ├─> T19 XA audio
 T4 packets / OTs ──> T5 VRAM       │                    ├─> T21 movies
        │               │           │                    └─> T18 SPU samples
        │               └─> T8 2D / UI / effects
        └─> T6 view & widescreen
 T4 + T7 ──> T1 loop, thread, clock ──> T2 true frame rate, T23, T18 off the game thread, T20 latency
 T3, T16, T20 (analog), T22   mostly independent
```

What this says in plain order:

1. **Nothing in memory can go until the pointers do (T13).** T12, T14, T15, T17 and T11 all wait on
   guest pointers being gone, struct by struct. The lint counts (`ps1_address_lint.py`) are the progress
   meter, and they only go down.
2. **The loop and clock (T1, T2, T23) are the last big step, not the first.** Separating rendering from
   the game's loop needs frames to be values (T4), the GTE not to be a global (T7), and the game's data
   not to be shared by raw address (T13).
3. **The disc chain runs in one direction: overlays (T10), then disc reads (T9), then everything that loads
   from the disc (movies T21, XA T19, sound samples T18).** Doing T9 alone would still leave overlay
   memory behaviour behind it.
4. **Several ties are independent and cheap:** T3 (scanline clock), T20 (analog and rumble), T22 (a native save
   file), parts of T16, and per-screen moves under T8 (the modern UI layer already shows the pattern).

### Which ties the player would notice if removed

- **Frame rate and smoothness (T1, T2):** the biggest. Menus, HUD and many effects would move at the
  display's rate; input latency would drop.
- **Widescreen, resolution and texture quality (T4, T5, T6, T8):** the sharpest visual effect, by screen: no
  4:3 culling, real hi-res UI, textures that are not 256-colour pages.
- **Loading (T9, T10):** possibly instant room and menu loads. Needs the data format work first.
- **Audio (T18, T19):** richer instruments or hitch-free audio. A smaller visible change.
- **Analog input (T20) and movies (T21):** easy to notice, easy to do, and limited by what the game's logic
  and media allow.
- **Invisible, but they decide the speed of everything else:** T7, T12, T13, T14, T15, T17.

## Where the docs are out of date

- `pc/docs/Modernization_Plan.md`: describes a 32-bit ABI, native code pinned below 16 MB for 24-bit
  ordering-table links, and a byte-identical PS1 build checked by `make commit-check`. The 64-bit
  build is the only one (the 32-bit build was retired); the game now lives in `pc/src/game` and is edited
  there ("Nothing compares it with an original", `pc/src/game/README.md`). Its progress notes
  ("32-bit remains the default") are history.
- `pc/docs/LP64_Audit.md`: a snapshot from 2026-10-09 (93 of 211 units failing to compile, no 64-bit link
  yet). The 64-bit build links and runs; use `ps1_address_baseline.json` for current counts.
- `pc/ASSEMBLY_INVENTORY.md`: paths are to the old top-level `src/` tree, and the count (95) differs from
  a current grep (97 `INCLUDE_ASM` lines in `pc/src/game`, including conditional ones).
- `pc/src/memory.c` and `memory.h` look like the memory model but only a unit test uses them; the real
  mapping is in `boot_runtime.c`.
- `pc/src/boot_runtime.c`'s `next_packet` and a few comments keep 32-bit branches (`sizeof(void*) == 4`)
  that cannot run now.
- `pc/docs/Modern_Menus.md` says the default is `original` "until the first screens are verified". The
  code's static default for `ui_menus` is 0 (`project_settings.cpp`); whether shipped settings change it
  is not confirmed here.
- `pc/src/psx_types.h`'s header says it is for "matched src/ code" whose objects stay byte-identical on
  the PS1. That no longer applies to `pc/src/game`.
- The name `ROOD_PC_BOOT_DIAGNOSTIC` (the define that switches the game's disc reads to the host read) is
  a leftover from the first slice; it is on in the normal build.

## What this map could not confirm

- Whether the build still needs the MIPS toolchain and the decompilation's build products for anything
  beyond symbol addresses and tables (no build was run).
- The current count of data imports at PS1 addresses (the last count, 941, is from 2026-10-09).
- Whether AI timing (T3), edge culling in widescreen (T6), audio underruns (T18) and input latency (T20)
  are actually noticeable in play.
- Which XA streams exist besides movie sound (T19), and whether the original uses vibration (T20).
- Whether a refresh rate that is not a multiple of 59.94 Hz judders with the present-rate scheme (T2).
