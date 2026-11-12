# T5 survey: VRAM, and what the game loop leaving `VSync` (T1) needs from it

Read-only survey, 2026-11-12 (line numbers from main at the time of reading; nothing built or run). Companion to
`2026-11-12-t4-survey.md`. Verdict: queue an ordered VRAM transfer stream with each frame and fence the few readers
of the rendered frame; retiring the CPU rasterizer comes later and is cleanup. The renderer thread needs the stream
either way, and retiring the rasterizer also drops the CPU reference frame (`build_compare --renderer null`,
`CPU-Oracle.md`) without removing the transfer events.

## 1. Writers of VRAM

The array is `static uint16_t vram[1024 * 512]` (`pc/src/boot_runtime.c:22`, exported by `pc_native_vram()`, :28).

- `LoadImage` / `LoadImage2`: `boot_sdk.c:90, :99` -> `pc_vram_transfer` (write) `boot_runtime.c:142-162`, which calls
  `pc_hw_before_write` (`gpu_hw.c:5002`) and `pc_hw_upload` (`gpu_hw.c:3371`). 60 game sites in 17 files (TITLE `22C.c` 14,
  MENUF `3B8.c` 12, INITBTL `18.c` 6, `main.c` 5, ENDING `D4.c` 5, Zig `func_800AB4F0/AB358/91FE8/AB098/AAC80`,
  `parse_shp`, `load_znd_tims`, `render_image.zig`). The palette write is one `LoadImage`: `vs_main_commitClut`
  (`main.c:11836-11842`) uploads the 256 x 14 CLUT block at (768, 224) when `uploadPending`; `vs_main_loadClut` uses
  `main.c:11693` for slot >= 14. Movies enter as `LoadImage` of MDEC output (`mdec.c` has no VRAM code); the display is
  read as 24-bit across halfwords (`boot_runtime.c:229-246`, `gl_present.c` `u_rgb24`).
- `ClearImage`: `boot_sdk.c:70` -> `pc_vram_rect` / `pc_vram_clear` (`boot_runtime.c:166-209`), 21 game sites in 7 files; the
  draw environment's clear `boot_sdk.c:345-347`.
- `MoveImage` / `DR_MOVE` (GP0 0x80): `MoveImage` `boot_sdk.c:839-850` builds a packet for `pc_draw_packet`; the copy is
  `boot_runtime.c:838-863` (stale-copy hook :844, `pc_hw_before_write` :846, `pc_hw_mark` / `pc_hw_copy` :861-862). 10
  `MoveImage` sites in 3 files; `DR_MOVE` packets inside the ordering table in battle (`func_800AB098.zig`,
  `func_800AB358.zig:64-69`, `func_800AACDC.zig`: an actor's texture-map frames), so they are ordered with the draws.
- The CPU rasterizer: `pixel()` `boot_runtime.c:730-760`; triangles `boot_polygons.inc:35` and `:140`; sprites and
  rectangles `boot_runtime.c` ~900-1010 (skip hook `pc_hw_raster_skip` :963, counters `PC_COUNT_RASTER_PX` :971,
  `boot_polygons.inc:102`). GP0 fill 0x02 is unsupported by design (`ClearImage` is the only fill).
- Host writers: `hud_bridge.c:2099, :2177` (`:1867` reads), `classic_parity.c:854` (held uploads), `dev_rpc.c:4332-4364`
  (test texture write), snapshot restore (`snapshot.c:383` range list, digest :1012), `state_rewind.c:199`, then
  `pc_hw_resync` (`gpu_hw.c:3532`; also `engine_reload.c:152`, `snapshot.c:890`, `photo.cpp:46`).
- Render-to-texture and frame feedback, the only writers that are not plain transfers: the cases `pc_hw_sync_texture` exists for
  (`boot_runtime.c:936-938`, `boot_polygons.inc:306-313`) and the memory card's CLUT swap (`gpu_hw.c:4938`, `op_rewritten`).

## 2. Readers

- `StoreImage` (`boot_sdk.c:100-107` -> `pc_vram_transfer` read, with `pc_hw_sync_store` `gpu_hw.c:4434`): 8 game sites.
  Frame readers: TITLE `22C.c:105, :4025, :4029, :4032, :4659`; MENU5 `4D8.c:307-308` (menu background backup); MENU7
  `260.c:211, :3546`. Texture readers (glyph cells): `render_text_immediate.zig:97`, `func_800C7EBC.zig:19`.
- The stale model: where native draws replaced CPU drawing the CPU copy is stale and is copied back from the GPU target on
  demand: `pc_hw_sync` (`gpu_hw.c:4432`; callers `boot_runtime.c:1250, :1378, :1464, :1487`: presenting, screenshot, checkpoint),
  `sync_kinds` :4439, `pc_hw_raster_skip` :4534, `vram_from_target` :4389. `Native_Rendering.md`, "Without reference
  packets", gives the rate: about one readback per 12 vsyncs in the soak, only screen effects that sample the frame.
- Texel upload to the GPU: an R16UI texture filled from `native_vram` per 64 x 256 tile (`upload_bands_from` /
  `upload_tiles_from` / `upload_dirty`, `gpu_hw.c:1624-1718`; `dirty_tiles` :1041, `pc_hw_mark` :1612). The interpolation
  replay keeps a second full VRAM (`replay_vram`, `gpu_hw.c:5324`) and a write log of 16 writes x 4096 halfwords per frame
  (`gpu_hw.c:4645, :4675, :5016`, `op_rewritten` :4938, `replay_unwrite` :5393).
- Record-time content readers on the game thread, against `native_vram`: `ui_text` (`gpu_hw.c:2498-2924`, `ui_text.c`),
  `ui_upscale.c`, `ui_emotes.c:53-396` (classifies images by texel hash), `button_prompts` / `button_roles`
  (`boot_runtime.c:812, :934`), `emissive.cpp:147, :1311, :1326, :1343-1585`, `environment.cpp:138, :199`, `ptgi.c:439`,
  `editor_view.cpp`, the state digest `snapshot.c:1012`.
- Presenters take the CPU array: `pc_window_frame(vram, ...)` `boot_window.c:437-460` (software/null path, rgb24 movies),
  `boot_runtime.c:1266, :1332, :1343`; `gl_present.c:1197` and `vk_present.c:409` call `pc_hw_init(pc_native_vram())`.

## 3. What a VRAM update stream queued with the frame needs

- Event kinds, in game order: upload (rect, payload copied at call time because the game reuses the buffer; KB typically,
  128 KB bursts at room loads, ~150 KB per movie frame, 7 KB for the CLUT commit), fill (rect, colour), copy (rect, from
  `MoveImage` and from `DR_MOVE` packets in the table), full resync (whole VRAM: snapshot, rewind, engine reload, photo;
  today `pc_hw_resync`), readback request (rect, a fence).
- Interleaved with the draw ops by sequence number, not a separate list: batches must sample VRAM as it was at their position
  (CLUT swap-in and swap-out for one sprite, `DR_MOVE` copies between polygons). The current replay machinery is a
  one-frame, 16-entry special case of this; the stream makes it exact and general, and the renderer keeps two frames of it.
- The renderer owns the R16UI texture and the scaled target and applies each upload to both (`pc_hw_upload` draws the
  rect into the target too, `gpu_hw.c:3371-3420`; `widescreen_screen_upload` special case :3395).
- What stays on the game side: a transfer-only mirror of VRAM updated by the same calls on the game thread, so the content
  readers above and snapshot / rewind work unchanged. It is exact for texture and CLUT areas because only transfers
  write them, except render-to-texture and feedback.
- Fences for the readers: `StoreImage` of the frame (TITLE, MENU5, MENU7), `pc_hw_sync_texture` feedback effects,
  screenshot and checkpoint presentation. The game thread waits for the renderer to retire the frames queued before the
  request; these are rare, local points.

## 4. Stream versus retiring the CPU rasterizer

- Retiring it (T5 proper) needs: a replacement for the reference oracle (`--renderer null`, `CPU-Oracle.md`, `Oracle.md`,
  the software present path `boot_window.c:437-460`, headless checkpoints); readbacks of the rendered frame by the three
  TITLE / MENU sites and feedback effects, i.e. the fence anyway; removing `boot_polygons.inc` (379 lines), the
  rect/line code in `boot_runtime.c` (~330) and the stale machinery in `gpu_hw.c` (~600-900 lines); re-deriving mask-bit
  and semi-transparency exactness. It does not remove the transfer events. Weeks, high risk.
- The stream does not need the rasterizer retired: with `raster_skip` and the stale model as today the CPU copy of the
  frame area may be stale on the game thread, and the three frame readers become fences. Only the transfer mirror must be
  exact. About two weeks of agent time: a new `vram_stream.c` (~400 lines), hooks at the write sites (`boot_runtime.c:142,
  :166, :195, :838` and the draw-env clear `boot_sdk.c:345`), the `gpu_hw.c` upload entry points rewired (:1675, :1683,
  :1705, :3371, :4468, :5005, :5331) plus `vk_hw.c`.
- For T1: stream and fences first (needed for a renderer thread either way: there is no way to apply uploads in order on
  another thread without it); retire the rasterizer afterwards as cleanup.

## 5. Slices, each provable with `build_compare` at 0 differ

- S0 (1-2 days, no behaviour change): a per-frame stream digest in the engine, hashed over (kind, rect, payload hash,
  draw-op ordinal) from the write sites, exposed through RPC and as one more hash per sampled frame in `build_compare`.
- S1 (2-3 days): completeness proof: a debug mode applies the logged stream to a fresh 1 MB array and compares texture and
  CLUT areas with native VRAM every frame on all routes; a mismatch is render-to-texture or a missed writer, listed with
  file:line. This decides how large the fence list really is.
- S2 (3-5 days): renderer-side VRAM from the stream on the same thread: `gpu_hw` uploads read from the stream-built copy
  instead of `native_vram`; `replay_vram` and `write_old` replaced by stream positions. Proof: frame hashes 0 differ on every
  lane including interpolation and the memory-card routes.
- S3 (3-5 days): fences: `StoreImage`, `pc_hw_sync`, `pc_hw_sync_texture` and screenshots become request and wait on the
  renderer's queue (still the same thread); snapshot / rewind / engine reload become a full-resync event. Proof: ending,
  title, MENU5 / MENU7 routes and the save-state and rewind smokes 0 differ.
- S4 (T1 proper, estimated separately): the renderer thread consumes frames (needs the T4 frame value and the record-time
  content readers fed from the game-side mirror).

## 6. Risks

- Ordering inside a frame: `DR_MOVE` and CLUT swaps; a stream applied after the batch samples the wrong texels (the memory
  card thumbnails witness this, `gpu_hw.c:4938`).
- Payload cost and lifetime; the stream ring must be saved state or rebuilt (a snapshot cuts at the vsync boundary).
- Determinism: stale readbacks quantize the GPU result to 5 bits (`gpu_hw.c:4466`), so any reader of a stale area sees
  GPU-dependent values today; fences keep that, but a renderer on its own thread makes the wait a visible hitch (rare:
  one per ~12 vsyncs in the soak, none in the first room).
- Hidden VRAM readers: 36 files mention `vram`; the S1 census is how to close that properly.
- The 24-bit movie display and the software presenter read the display rectangle from the CPU array.
- Tests and oracles that assume the CPU frame stay valid only while the rasterizer stays.

Not covered: the T4 item details, and the T13 / T17 state sharing a renderer thread needs.

## 7. S1 result: the writer and feedback list (the S3 fence list)

`ROOD_VRAM_STREAM_CHECK=1` replays the stream (upload, fill, rect fill, copy, resync rebase) into a shadow array and compares
every vsync every pixel the CPU rasterizer or a resync has not touched; `ROOD_VRAM_STREAM_CHECK_OUT=<file>` writes the
sampling census (64x64 VRAM blocks, tpage of the sampling primitive) every 60 vsyncs. Run through `build_compare.py --play-menus`,
`--play` and `--play-casts` (one binary, one route).

Writers: 0 differing pixels on every route run: title, mainmenu, manual, levelled, items, magic, arts, abilities, status,
score, map, data, setup, loot, storage, ending, menuf, dialogue, gameover, opening_events, platforms, story_evt-0001,
story_evt-0069, story_room-001-00-s000, story_room-032-17-s038, the fight (30 s), `--casts drive` (40 actions) and
`--casts spells,arts` (60 actions). The stream has every writer these routes reach.

Frame feedback (the rasterizer sampling a pixel it or a resync wrote; the fences S3 needs):

| Reader | Where it samples | tpage (low 8 bits) | Routes |
|---|---|---|---|
| display-area copy, the 640x64 band at y 128..191 | x 0..639, y 128..191 | 0, 4, 5, 9 | every menu route above, title, platforms, the fight (TITLE 22C.c, MENU5 4D8.c and MENU7 260.c frame readers) |
| the same band plus y 192..255 | x 0..639, y 192..255 | 0, 4, 5, 9 | manual, setup, score, status, map |
| the band plus y 0..127 | x 0..639, y 0..127 | 3, 8, 32, 34, 37, 39 | map, score, status (screen captures drawn as sprites) |
| storage and manual only | y 128..191 | 34, 39 | storage, manual |

None on dialogue, opening_events, the story routes, `--casts` (spells, arts, drive): no fence needed there. The fight's
only feedback is the same y 128..191 band. In every case the pixels read were written by the CPU rasterizer (the display
frame), never by an upload or a fill the stream lacks, so the fences are the three frame readers already listed in section 2
and nothing new.

## 8. S2 and S3 as built

S2 (same thread): `gpu_hw.c` keeps its own VRAM (`rvram`), written only by the stream's upload, fill and copy events and by the
GPU read-backs; the sampled copy, the UI text and upscale lookups and the replay undo read it. `ROOD_VRAM_RENDERER=native`
samples the game's array instead. The CPU rasterizer's pixels are not events: `pc_hw_mark_raster` marks the bands and
`raster_refresh` takes them from the game's array when the renderer next reads them (RPC `vram_stream` "renderer"
`raster_bands` counts them). That refresh is the one remaining read of the game's array by the renderer; a renderer on its own
thread needs the rasterizer's output posted as events (S4) or the CPU rasterizer retired (section 4). The write log
(`write_old` replaced) lets a recording be undone across any number of writes of up to 64K halfwords (8192 writes in the ring).

S3: the game-to-renderer read-backs are the fences, now stream events (kind 6: cause and rectangle), counted by cause in RPC
`vram_stream` "fences": `store` (StoreImage) and `texture` (a sprite sampling the frame being drawn). On the routes of
section 7 only `texture` ever copies back (map 2, storage 2, manual 1, setup 13, score 8; everything else 0) and `store`
never does: the TITLE / MENU5 / MENU7 frame readers read native VRAM the CPU rasterizer already holds. The fences a renderer
thread must wait at are these two calls plus the `raster_refresh` bands.
