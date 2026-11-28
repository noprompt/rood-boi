# A native renderer: draw the game's state, not the PS1's GPU

Status: plan, revised 2026-11-27 (second version: PS1 pixel parity dropped, Kagero's approach taken where it fits). Written from the
code at 8ba6ecc75 by reading it (nothing built or run). Sizes are agent-days (one worker, `-j 1`), not calendar time.

## What changed in the brief

1. **PS1 pixel parity is not a goal.** Classic mode need not be bit-exact; the pixel lanes and `classic_parity` are not gates. The bar is
   "does not fundamentally break the game", plus screenshots for the user's eye wherever a picture visibly changes.
2. **Kagero's shape** is the target: the game publishes typed data once per fixed step, the renderer reads only that and interpolates
   between the last two; assets are converted offline; screen effects are typed quads; 2D is typed sprites and text; logic that tests
   the screen never asks the renderer; correctness is a state trace plus paired frames, with the original's look values as defaults.

The first version of this plan (VRAM replaced by a runtime image registry, steps N0 to N8, 36 to 52 days) is superseded below.

## 1. What exists, and what each piece still lacks

- **rood-studio, `native_model`**: SHP, WEP, ZUD decoded from the disc with no game. Lacks: the decoded texture is written back into the
  emulated VRAM image because the renderer samples by page and CLUT.
- **Native room, character and effect meshes** (`room_native.c`, `actor_native.c`, `effect_native.c`): world-space instances with the
  game's matrices. Lack: ids that survive from one step to the next (interpolation matches triangles by "nearest with the same surface",
  `replay_frame`, `op_feedback`), and a texture reference that is not a VRAM address.
- **Draw items** (`draw_items.c`): typed (tile, sprite, polygon), ordered by depth, no ordering-table packets left (`ordering_table` 0,
  `gpu_packet_writes` 0). Lack: they carry what the GTE returned (screen pixels) and a page plus CLUT, so they are a typed copy of a
  packet, not a description of what is shown. Widescreen anchoring is a hint the game sends the renderer (`pc_hw_anchor_packets`,
  about a dozen call sites in battle and field code), not a field of the item.
- **Modern menus, HUD, `ui_text`**: native layout and fonts; the game decides rules. Lack: nothing structural, they already read a state
  and draw it.
- **RT/GI** (Vulkan, probes, shadows, NRD, post): needs a sampler that returns a colour and a stable content key for materials; no more.
- **The post stack already works in display-referred values until step 3** (`Post_Processing.md`: "into linear light (the PS1's
  display-referred colours: a 2.2 power)"), which matters for the screen quads below.

## 2. Snapshot plus typed draw data: what changes in rood-boi

Today the renderer's input is the stream of what the game drew: recorded ops (`record_vertices`, `record_fill`), a write log and a
replay VRAM so an interpolated frame can redraw the old stream with moved 3D (`replay_frame`, `replay_sample_own`, `op_feedback`,
`replay_unwrite`: the interpolation section of `gpu_hw.c`, about 1,000 to 1,500 lines). Interpolation is the renderer's job already and
logic never reads it; what is missing is identity and a typed description.

Change: each fixed step the game publishes a **snapshot value** (the T1 renderer thread already takes a finished frame as a value; this
is that value with ids, kept two deep):
- the camera and the room (id, group matrices, flags that hide groups);
- actors and props by id: model id, pose (bone angles or matrices), palette selection, colour/blend state;
- effects by id: kind, position, size, colour, blend, texture frame; shadows and particles likewise;
- HUD and menu values (numbers, bar fractions, selected row), which the modern UI already consumes;
- typed 2D items in logical coordinates with an anchor (left, centre, right, stretch) in place of the packet-position hints;
- screen effects (below) and palette writes (below).
The renderer reads only this. It interpolates entities present in both of the last two snapshots by id, draws entities in only one as
they are, and never touches game structs: today it still does, at record time (`ui_text`, `emissive.cpp`, `environment.cpp`, `ptgi.c`,
`ui_upscale.c`, button prompts read `native_vram`; the `vram_pointer` lint shows 11 sites). Logic never reads an interpolated value
(it does not today). Lint rule to add in the first step: no file under `game/` or `pc/src/game` names a renderer symbol (found now:
`pc_hw_anchor_packets` and `pc_hw_opacity_on` and `pc_hw_opacity_packets`, all hints or settings going the other way, which become
snapshot fields).

## 3. Assets converted offline, and what that does to the registry

A converter reads the disc and writes native files (cached under the user's data directory from their own disc, never committed or
shipped): room geometry and textures, models with clips, menu and effect sheets cut into named sprites, movies. Palettes are resolved to
RGBA at conversion; textures are keyed by the content hash of the converted pixels, so a material or emissive file keys the same way at
run time as it does now (today it keys by the md5 of VRAM texels plus palette; the converter computes that key once).

**Palettes that must stay live data.** Most CLUTs are fixed once loaded and are baked: models' and rooms' palettes, the alternate
palette of a material group (`+0x480`, a second baked palette chosen by a flag in the snapshot), UI palettes. What the game rewrites
while it runs stays a palette object (id plus 16 or 256 RGBA entries) written by a typed "set palette" in the snapshot, with the texture
kept as indices for those slots only: enemies' flashes and colour cycles (`Materials.md`, "Animated palettes"; the emissive palette
animation smoke covers them), the room gimmick palette block (`vs_field_setGimmickPaletteTable`, 0xE0 bytes, animated by gimmick
instances), effect plug-ins that run a colour ramp, and the memory card screens' CLUT swap for save thumbnails. `vs_main_loadClut` has
33 call sites in 18 files; the first step lists which are one-shot and which run every step. Room texture effects: types 0, 2 and 6 are
UV or matrix changes already; type 1 (544 effects in 325 rooms, `MoveImage` of atlas frames or a scroll) is converted to frame images
and runtime is a frame index or offset in the snapshot, so it needs no image operation.
What does not convert: textures the game composes itself at run time (text boxes drawn into VRAM and read back by `StoreImage`:
`render_text_immediate`, `render_image`, the card thumbnails, a menu's frame backup). These stay **dynamic images**, but small and
named: typed text replaces the first, a snapshot item the frame backup (section 5).

**Offline against the runtime registry (N1 and N2 of version one).** The registry (ids from content hashed at `LoadImage`) and the
converter produce the same ids, so they are not alternatives: the registry is the cheap bridge that works for everything the game
uploads, converted or not; the converter replaces its source class by class. Net: the converter replaces N1 (3 to 4 days) and most of N2
(3 to 4) with more work up front (about 10 to 16 days) but that work is also N5 (menu sheets), the movie step and rooms' texture
animation (N4 shrinks from 4 to 5 days to about 2), and models are nearly free because `native_model` already decodes them. Models
first, then room textures, then sheets. The step list keeps a small registry (hash a rectangle at `LoadImage`) as the bridge for
assets not converted yet.

## 4. Screen effects as typed quads, and the colour space

PS1 tints, wipes, fades, flashes and semi-transparent overlays (screen fade `pc_renderer_frame_state.fade`, `vs_field_beginScreenFadeOut`,
`draw_screen_transition`, `vs_render_drawGimScanlineWipe`, MENU5's darkening, damage and spell flashes) become **typed screen quads**
in the snapshot: rectangle, colour, blend mode (add, average, subtract, add-quarter, opaque), depth order among 2D items. They are
blended in one place, the final composite. The PS1's add, average and subtract operate on display-encoded values (5-bit, a 2.2 curve
applies on the display). So the quads are composed in display-referred space, before the post stack's "into linear light" step, and
clamped as the PS1 clamps. Added in linear light after that step they come out too dim: a flash adding 0.5 to a 0.5 pixel is 1.0 in
display space but 0.22 + 0.22 = 0.44 linear, 0.69 when encoded back. Scene-space translucency (window glass, particles in the 3D pass)
keeps its present treatment. Bloom and grade then see the same values as today.

## 5. 2D, menus, text, screen copies

- **Sprites and text** are typed items naming a sprite in a converted sheet (cut by the converter from the original sheets: TITLE, MENUF,
  ENDING, MENU5/7/E, MAINMENU, HUD) and text items (`ui_text` fonts). Classic UI keeps the original sprites and layout.
- **Screen copies** (cross-fades, backdrops sampled as textures, the TITLE and MENU5 `StoreImage` frame reads, `WINDOW_CAPTURE`):
  a **snapshot item** ("keep the frame so far as image N") and items that sample N. The game's three frame readers ask for N instead of
  pixels in a buffer.
- **Movies**: the decoder (`mdec.c`) writes a video image the presenter shows, not 24-bit VRAM; offline re-encoding to a modern video
  format is possible later and not needed.

## 6. Logic that tests the screen

The game already does this on its own integer projection and never on the renderer. Found by reading: the rain drops
(`func_8008F440.zig`, `func_8008FDC4.zig`: `gte.project`, then x in 0..320 (minus or plus a widescreen margin of 54), y in 1..239, depth
5..2047), particles (`func_80090434.zig`: x < 320, y < 240) and the "centred" test of `compute_step_and_displacement.zig` (the
projection's x and y against 61..259 and 60..180, which sets `notCentered`). 65 files use the GTE projection. All stay as they are:
the integer GTE at 320x240, the original's, with the widescreen margin where the game already has it. The renderer may show more than
that (wider, supersampled) without changing what the game decides. What to confirm in the first step: no game code reads the target or
VRAM for a decision (the lint above, and the `StoreImage` sites: the survey lists frame readers in TITLE, MENU5 and MENU7 and two glyph-cell readers; each is to be read to confirm it feeds a display, not a decision).

## 7. Correctness without pixel lanes

- **State trace as the routine check.** `build_compare` already compares game state per step (the fight lane reports "120 steps, every
  named field of every actor equal"; RPC `snapshot hash`, `record` and `replay` exist). Make it the first gate of every change: recorded
  input runs (fight, 8 rooms, casts, menu routes, title to a battle) replayed on the previous binary and the new one with
  `ROOD_RENDERER=null` and fast stepping, comparing the per-step state digest. It needs no picture, no GPU and runs in minutes;
  nothing the renderer does can change it, so a mismatch is a logic or snapshot-publishing bug. A `--states` lane for `build_compare` that
  does only this.
- **Paired frames.** A tool that takes the same state (a snapshot of the reference build at a route step), renders it with the reference
  binary (the last exact build, kept) and the new one, writes the pair side by side and the mean luminance and per-channel means of
  regions (sky, floor, HUD, a lit actor); anything a step changes visibly is listed with its measured brightness ratio and goes on a
  sheet for the user.
- **Defaults are the original's look values.** Kagero's rooms drifted to a third of the original's brightness unnoticed. Rule: the
  default look preset equals the measured original (reference screenshots from the current build on the build_compare routes; mean
  luminance per frame within 3 per cent, flagged otherwise); GI, bloom, tone mapping, supersampling and the rest are enhancements that
  the player turns on. This is also the check for the colour-space point in section 4.

## 8. Classic mode

The same native renderer with its original look: nearest filtering, 15-bit quantization on, PS1 draw order, no GI or post, 4:3. It is
checked by the state trace and by paired frames against the reference screenshots (brightness and layout), not by pixels, so dither and
the GPU's rounding may differ; the classic UI promise (original sprites and layout with modern UI off) stays.

## 9. Steps, each leaving main playable

| Step | What | Proof | Days | Removes |
|---|---|---|---|---|
| K0 | The state-trace lane (`--states`), the paired-frames tool, the reference screenshots and brightness table; the lint rule "no renderer symbol in game code"; inventory of every `LoadImage`, `MoveImage`, `ClearImage`, `StoreImage` and `vs_main_loadClut` writer (one-shot or per step), and of dynamic-image producers | the lane passes on the current binary against itself and against the previous commit; the inventory is a table | 3-4 | nothing; every later step gets a cheap gate (state trace in minutes in place of 40-minute pixel lanes) |
| K1 | Typed screen quads and fades (section 4) in the snapshot; final-pass composite in display-referred space | state trace; paired frames on fades, flashes, wipes, MENU5 darkening; user sheet | 3-4 | fade and wipe items drawn as 2D polygons, the screen fade special case in `pc_frame_state` |
| K2 | Content ids: a rectangle's hash at `LoadImage` gives an image id; meshes and items carry the id next to the page | state trace, materials and emissive smokes (same keys) | 2-3 | the texel hashing at match time (~1,100 hashed texels a vsync in the field) |
| K3 | Converter, models and clips: native_model's output written to files and loaded in place of the loader's upload; palettes baked | state trace; paired frames on 8 actors and weapons | 3-4 | the texture-slot machinery for models (slot origins, row offsets, the VRAM fill by the loader) |
| K4 | Converter, rooms: geometry, textures, baked palettes, type 1 effects as frames; gimmick and flash palettes as live palette objects | state trace; paired frames on 8 rooms; palette-animation smoke | 5-7 | the 128 KB room upload bursts, `MoveImage` room animation, CLUT row uploads for those palettes |
| K5 | Shaders sample images and palette objects instead of the R16UI array (4-, 8-, 15-bit paths gone for converted assets; texture window and mask bit where still used by the game) | paired frames on every route, reviewed differences; user sheet | 5-8 | the VRAM texture upload bands (`upload_bands`), upload KB, own-copy compute pass |
| K6 | Converter, sheets: menu, HUD and effect sheets cut into named sprites; items name sprites; text items from fonts; widescreen anchors as item fields | state trace; menus lanes by paired frames at 4:3 and 16:9; user sheet | 6-9 | the remaining sprite-sheet uploads, `StoreImage` glyph reads (`render_text_immediate`, `func_800C7EBC`), anchor hints |
| K7 | Snapshot publication with ids for actors, props, effects, camera, HUD; renderer interpolates by id between the last two; screen copies as snapshot items; the TITLE and MENU5 frame readers ask for an image | state trace; interpolated fight and menus by paired frames; TITLE and MENU5 routes | 8-12 | the recordings, `replay_frame`, `op_feedback`, `replay_unwrite`, `replay_vram` and the write log, `WINDOW_CAPTURE`, own copies, `pc_hw_capture_read`, `pc_hwc_fence_sync` |
| K8 | Movies into a video image | the intro and one in-game movie, by eye and the end-of-movie state | 3-4 | `pc_display_rgb24`, the 24-bit VRAM display |
| K9 | Delete the array, the scaled VRAM-sized target, the stale marks and read-back code; `vram_*` lint meters at 0; save states and rewind (decision below) | whole gate once: state trace, paired frames, save-state and rewind smokes | 4-6 | `vram` and its mirror (1 to 2 MB), the target (4096 x 2048 RGBA8 at scale 4: 32 MB, plus its multisample set), 600 to 900 lines of stale and own-copy code, ~1,000 to 1,500 lines of replay |

Total **42 to 61 agent-days**, against 36 to 52 in version one. The basis: the T5 lane's pace (this session's removals each took 0.5 to
1.5 days with a gate), the 2026-11-12 survey (about two weeks for the VRAM stream), and read sizes (`gpu_hw.c` 6,545 lines; `vk_hw.c`
1,263; `ui_text.c` 3,545). K0, K1, K2 and K3 are the cheap ones and leave the picture as it is; K5, K6 and K7 carry the uncertainty (no
exact reference for K5; K6 has many screens; K7 is a rewrite of how interpolation finds an entity).

**What got smaller.** Texture and palette work (N1 + N2 + N4 of version one, 10 to 13 days) is about 10 to 14 as K2 + K3 + K4, but it
carries models, rooms and part of the sheets with it; the shader step falls from 8 to 12 to 5 to 8 (no texture-window or mask-bit
exactness to chase); proofs fall from a 40-minute pixel gate to a state trace in minutes plus reviewed pairs, which is the CPU cost the
user is tired of; palettes shrink to the live subset (a handful of animated palettes instead of every CLUT); room texture animation
becomes frame indices.
**What got bigger.** The snapshot with ids and interpolation by id (K7, 8 to 12 days) is new work: version one kept the current recorded
streams; the converter is real code (K3, K4, K6: 14 to 20 days for three asset classes), including its own coverage test; the
paired-frames tool and look table (K0) are new tooling.
**CPU cost removed**, by step: K2 the per-frame texel hashing; K4 and K5 the upload work (room-load bursts, band uploads, own-copy passes
26 passes and 83 barriers a vsync on interpolated sphere before 89e244e7b, now 26 and 59); K7 the replay of recorded frames; K9 the
VRAM-sized target's bandwidth and its state hashing in snapshots.

## Decisions for the user

1. **Save states** hold the VRAM array (`snapshot.c`). K9 needs a format change or a shim that rebuilds images from a legacy array on
   load. Formats are on hold, so K9 waits on this; K0 to K8 do not.
2. **Converted data is local.** The converter writes files from the user's own disc into the data directory; nothing derived from the disc is
   committed or shipped (assumed here; say if a different arrangement is wanted).
3. **Start with K0 to K3**, which leave the picture as it is and change what every later step costs to prove; K5 is the first step that
   can change a picture and the plan stops there for the user's eye.
