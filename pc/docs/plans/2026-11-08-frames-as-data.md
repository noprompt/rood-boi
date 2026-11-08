# Frames as data

Status: T4 of [off-the-ps1](2026-11-08-off-the-ps1.md) ([PS1_Ties.md](../PS1_Ties.md)), started 2026-11-08.
API: `pc/src/draw_items.h`, `draw_items.c`. First screen: ENDING.

## Where it ends

The game builds a frame as a list of typed draw items (tile, sprite, polygon, later line, text, copy) with a
depth to sort by, a draw mode and a texture reference. Nothing writes a GPU packet, links an ordering table or
bumps `vs_scratch.unk0`. A renderer thread can take a finished frame as a value (T1).

## The API

One frame list, built on the game thread (`pc/src/draw_items.h`):

- `pc_frame_begin()` starts a frame. `pc_frame_add(kind, depth)` appends a zeroed `pc_item` to fill;
  `pc_frame_sprite` and `pc_frame_tile` fill the common ones.
- `pc_item`: `kind` (tile, sprite, polygon), `flags` (semi-transparent, raw texture, textured, shaded), `verts`,
  `mode` (the GPU draw mode: texture page, blend mode, colour depth, dither), `clut`, `depth`, corners `x[4] y[4]`,
  size `w h`, texels `u[4] v[4]`, colours `rgb[4][3]`. 52 bytes. Positions are screen pixels (a polygon's come from
  the GTE as before: the item stores what `RotTransPers4` returned).
- `pc_frame_draw()` draws the frame, as `DrawOTag` did a table.

**Order.** A larger `depth` draws first (the ordering-table slot number the game used); within one depth the later
submission draws first, as a packet linked at a slot's head did. The tie rule is the PS1's on purpose (no behaviour
change); a screen that stops relying on it can flip it for itself.

**State packets become fields.** `DR_TPAGE` inserts (`_insertTpage`) set the draw mode for the primitives drawn
after them in the walk. The items carry it: a sprite, tile or untextured polygon has `mode`, and the packet's old
position told which mode it drew with (the tpage inserted after a primitive in the same slot draws before it:
`_renderVagrantStory`'s two sprites, the background's two sprites and its bars). A textured polygon carries its own
page in `mode`, as its packet's tpage word did. `PC_ITEM_MODE(getTPage(..))` makes the mode word `SetDrawTPage`
made (dither on). The drawing area, offset and draw-environment tpage stay with the draw environment
(`PutDrawEnv`), which is not a packet; the mask bit and texture window have no user in ENDING and will become item
fields (or a frame header's) when a screen needs them. The host emits a mode packet only where an item needs a mode
other than the GPU's, tracking what textured polygons set.

## Order against what is still a packet (the transition)

`pc_frame_place(first, count, ot_entry, packet)` links a four-word marker (a GP0 no-op, the pattern of
`render_list_link` and the translucent markers) at an ordering-table slot. The walk in `boot_runtime.c`
recognises it and draws items `[first, first + count)` there, in item order among themselves, with the drawing
state in effect at that point. So a run of items sits exactly where its packets would have: before and after
other packets at its slot as the link order says, among native lists' markers, and under the same draw
environment. Markers hold only indices, so they survive a save state (the list is saved state).
A frame with no packets left does not need an ordering table at all (`pc_frame_draw`). The cost of a marker is
four words of packet memory, which is why a converted screen drops the table only when the whole screen is
converted. ENDING uses both: the credits are items alone; the MISSION COMPLETE frame is an ordering table whose
backdrop is an item run placed by a marker ahead of the leaves.

## How the renderers get it

The host lowers each item to the GP0 words the game used to write (`lower` in `draw_items.c`: the same layout
a `POLY_GT4`, `SPRT` or `TILE` had), into a host buffer with one distinct stable address per item, and hands them
to `draw_packet` as an ordering-table member (`pc_draw_item_packet`: chain mode 2, so `pc_gpu_immediate` is 0 and
`drawing_tag` is set as for a walked packet). Everything downstream is unchanged and sees the same words:

- the CPU rasterizer and reference VRAM (T5): items reach it through the same `commands()`, for as long as VRAM
  exists, so a screen that reads VRAM back shows what it showed;
- the hardware path (`pc_hw_*`, `gpu_hw.c`), which both renderers share (Vulkan in `vk_hw.c`, OpenGL behind the
  same `pc_hw_*` calls): nothing renderer specific was needed, OpenGL builds unchanged;
- `ui_text`'s glyph recognition (by texels and CLUT), widescreen classification and anchoring
  (`pc_hw_anchor_packet`, the GTE projection log: the lowered words carry the same coordinates), interpolation
  matching (keyed by packet address: the arena address is the item's index, stable like a buffer slot);
- the classic layer: see below.

This lowering is the transition. When T5 removes VRAM, a renderer entry `pc_hw_item(item)` replaces `lower` +
`commands()` for items: the item already has what the hardware path needs (corners, texels, clut, page,
blend, colour). Vulkan gets that first.

## Where items live

A static array in the saved-state section (`PC_SAVED_STATE`, as `render_state.c`): 1024 items, 53 KB. The game
builds a frame, waits for the vsync, then draws it (`_drawScreen`); a save state or rewind taken at that
vsync must keep the frame, so the list is saved with the game's statics and not rebuilt. It is reset by
`pc_frame_begin`. The lowered packets (a malloc'd arena) are derived at draw time and not saved. A frame
that overflows logs once and drops items; the capacity grows with the screens converted (MENU and BATTLE need
more) or becomes an arena sized by use. A renderer thread takes a finished list by value into a ring of two or
three (the list is plain data, no pointers).

## ENDING: what was converted

All of the credits (`D4.c`): the background, the scrolling text with its underlines, the illustrations,
the PHANTOM PAIN logo (a GTE-projected polygon grid), the VAGRANT STORY title, FIN, the copyright and the
skip fade. They draw into the frame list; the credits loop no longer touches the ordering table, the packet
buffers, `vs_scratch.unk0/4/8`, or `ClearOTagR`. `_insertTpage` and an unused `SPRT_8` routine are deleted. The MISSION
COMPLETE backdrop (`func_8006C3CC`, five polygons) is an item run placed by marker.

**What stays packets, and why.** The MISSION COMPLETE leaves (`renderTextures.h`, 12 hits, shared with MENUF's
3B8.c) and the ordering table that holds them. They are the classic layer's `menuf` site
(`pc_classic_site`, default on): the game's packets between two cursor values are suppressed and the Lua
claim (`rood.classic`) emits its own packets into the slots `unk4 - 28` and `unk8`, by walking packet memory and
the scratchpad slots (`classic_bridge.c`, `hud_bridge.c classic_finish`, `pc_classic_suppress`). That is a
packet protocol end to end, and MENUF shares the leaves. Converting the leaves means moving that layer to items
(a site's range is an item range; suppress marks items as `PC_ITEM_NONE`; a claim emits items at a slot depth),
which is the same step MENU needs and not ENDING's alone. ENDING was still a good proof: it holds a mixed
frame (items among packets, one slot's order against the leaves), a GTE-projected polygon set, the tpage-after
pattern, translucent subtract blends, and the two ways a frame ends.

## What depends on packet memory (found in ENDING and its neighbours)

- The packet cursor `vs_scratch.unk0` is read and bumped by every emitter; unk4 is the table base every slot is
  relative to; unk8 a second slot base (menus, the classic layer). Items replace the cursor and the slot
  arithmetic with a depth.
- Double buffering: the packet buffers and tables are per frame buffer (`D_8005E0C0[frameBuf]`,
  `D_80055C80[frameBuf]`), 0x20000 and 0x2088 bytes from the heap. A frame list needs one buffer per frame in
  flight, not per display buffer.
- Read-backs: ENDING reads no packet back. The classic layer, the HUD bridge and `ui_text` do (ranges between two
  cursor values, `drawing_tag`, the next packet linked, popup digits): they are the real users of packet identity.
- `DrawSync(0)` is a no-op here (drawing is immediate); ENDING keeps its two calls. With a renderer thread it
  becomes "wait for the previous frame".
- The game waits for the vsync between building a frame and drawing it, which is why the frame list is saved state.

## Checks

Frames of the old (packet) and new builds, deterministic runs from the same save: the display hashed every 10
vsyncs through the whole credits (27 431 frames), through MISSION COMPLETE, its fade-out and the screens after, and
every vsync through MISSION COMPLETE and its fade-out; old against old is the control. All identical.
Not covered: 16:9, `present_rate` above 1 (interpolation), the OpenGL renderer, ui_text scales other than 1.
`ps1_address_lint` `gpu_packet_writes` counts packet construction (see `ps1_address_lint.py`).
