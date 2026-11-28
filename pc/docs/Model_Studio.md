# The model studio

Design: `pc/docs/plans/2026-11-22-model-studio-and-paint-channels-design.md` (section 4, phase P2). This page is what is built.

A neutral workshop in which any model can be summoned and looked at from every side: a character, an enemy (with its weapon and shield) or a weapon. Code: `pc/src/studio.cpp` (the host: look, camera, catalog, RPC, the Studio window), `pc/src/studio.c` (the game side: the stage and the summon), `pc/src/studio.h`. Proof: `pc/tests/studio_smoke.py`.

## How it holds the game

The studio is a client of the photo mode (`photo.h`). Entering holds the game at a vsync boundary M ("studio" owns the pause, the camera session and the hidden HUD). Every picture is a photo mode render: the game runs a few frames from M, then its state is rewound to M with the picture kept. Two hooks were added to photo parts: `render` (a render is about to run, the game at M) and `landed` (it has ended, the game at M again).

At each render's start the studio calls `pc_studio_scene` once (studio.c):

- the loaded room's geometry block is overwritten with the stage (below), the room's actors are skipped, the room's light triangles are replaced by one colour so the models take the game's shading evenly (`stage.actor_light`), and the model is built in a spare actor slot (1..9) as the Bestiary builds its enemies;
- nothing built is undone: the render ends by rewinding the guest's memory, so what leaving the studio leaves behind is the game as it was held. The state digest (heap, VRAM, overlays, vsync) is equal before and after.

What is not in guest memory is given back by hand: the sun and sky (`pc_env_studio`, a transient layer in environment.cpp), the room settings (`pc_room_look_set`, the cutscene player's transient layer), the fog switch, the occlusion switch. Leaving does one last render of the game as it is (the renderers keep what they built from the last picture: the stage's ray-traced scene), then releases the pause, the camera and the HUD.

Summoning reads the model's files from the disc image (`pc_ui_disc_read`): `OBJ/%02X.SHP` (a character), `OBJ/%02X.WEP` (a weapon, held by a rig model, `model.rig`, whose body is not drawn), `MAP/<file>.ZUD` (an enemy: model, weapon, shield, sequences). A SHP whose texture block names another model's (about a third of them) gets that model loaded first, hidden. The loader ids the models are filed under (`model.loader_id`, 200) are numbers the room's actors do not use.

Framing: the render before measures the world-space box of what it drew (`actor_native.c`, from the bone palette and the vertices); the camera's target and distance come from it, one render later than the summon (the studio asks for that render itself). The stage grows with the camera's reach (`stage.reach`, `stage.max_scale`): a dragon is a model of 1500 units.

A live game's hold is led (photo.cpp: the last frames replayed to M), so the render's first frame is the replay's first: the studio's scene is built there, and the replay's frames draw it (built only for the replay's last frame the room's own picture stayed on screen). The Studio window is the state line (in the studio / Leave, or Enter) and two columns that scroll on their own, the controls and the catalog (`window.controls_share`), so it works docked short and wide; RPC `studio state` reports what it drew (`window`). Proof of the live editor path: `pc/tests/studio_window_smoke.py`.

## Data

`pc/assets/studio/studio.json` (shipped) with the user's overlay `pc/user/studio/studio.json` (`ROOD_STUDIO`) deep-merged over it: `stage` (radius, fillet, height, grey, facet sizes, reach), `camera` (yaw, elevation, fov, fit, guesses), `model` (facing, animation, equipment, rig, materials), `looks` (`neutral`, `flat`: sun, sky, room settings by their `room_settings.cpp` keys, fog, occlusion). RPC `studio` reads and sets any member by its path and saves the overlay; the Studio window (Window > Studio) shows every number as a row and the catalog as a list. `pc/assets/studio/catalog.json` is ids and file names only, written by `pc/tools/studio_scan.py` (`--check` compares) from the disc's file tree and MENU9's ZUD table; the enemies' names come from the player's own disc (SMALL/MON.BIN) when the studio runs.

Looks: `neutral` is a key light (a sun) and a sky, the room's own lights, glows, haze and fog off; `flat` is ambient light only (the stage is its grey exactly, the model shows its own colour). Fill and rim lights and the movable lights are P9.

## RPC `studio`

`{action}`: `state` (default), `enter`, `leave`, `summon {kind: character|enemy|weapon, id}`, `clear`, `camera {yaw, elevation, zoom, fov, orbit_yaw, orbit_elevation, zoom_by, frame}`, `look {name, set: path, value, save, reload}`, `get {path}`, `list {kind, filter}`. The reply carries the state: entered, settled (no render waiting), framed, the item, the camera, the box, the stage's size, the scene's message.

## Turntable and backdrop

`turntable` (data, window, RPC `studio {action: turntable, model, light, model_speed, light_speed, paused, fixed_dt, reset, model_angle, light_angle}`): the model itself turns (its facing; the camera stays) and/or the key light's azimuth goes round it, degrees a second, negative the other way; each render steps by speed x the time since the last (`fixed_dt` fixes the step for tests), `paused` holds the angles. `backdrop` (`{action: backdrop, mode: stage|solid, color: [r,g,b], preset: black|grey|white}`): `solid` has no stage and no drop shadow and draws the game's own background in one colour (its sky dome's five colours equal, tiles off), exact to the pixel and not lit; the model keeps the look's key light and sky. Interpolation is off while in the studio (the game's frame interpolation); rood-studio's animation is smooth by itself, see below.

### Where a model stands, and how sharp the studio draws (2026-11-27)

- **The feet are on the stage.** The stage's floor is y 0 and the model's place is y 0; the sequence's first vector (`pose.offset`, the hips' height) is scaled by the actor's scale (1820 of 4096) when the game adds it to the place (the root of Character 03 in animation 101: offset -312, world -138.6; measured against the game's own palette, `rood_studio` run with `--reference`). The native pose added it unscaled, so every character in rood-studio stood about 170 units up (Character 03, every frame of animation 101: lowest point -174 against the floor at 0; in the in-game studio the same pose is 2.6 above its floor). `pc_nm_pose_transforms` now scales it; the soles are 0.7 units above the floor. No "ground to the lowest point" rule: that is not what the game does, and a jump, a fall or a crouch would be pinned to the floor; the pose's own height is the animation's. `rood_studio_smoke` checks the lowest point of a summoned character against the floor.
- **Render quality is data** (`render` in studio.json): `height` 1080 (the internal resolution is the window's height or this, whichever is larger: gpu_hw.c's detail view with a least height; the picture is scaled to the window), GI and its denoiser at one pixel to a line of that (`gi_resolution` 0: height / 224; 4.82, capped at 5), `widescreen` (rood-studio's picture is 16:9 in a window wider than 3:2), `window_width` x `window_height` (rood-studio's default window, 1920 x 1080; `ROOD_WINDOW` wins). The in-game studio takes `height` and `gi_resolution` while it is entered too, and gives the game's settings back on leaving (the photo mode keeps the picture it marked at the scale that was then and wants that scale back to restore it: `gpu_hw_photo.inc`). The game outside the studio is unchanged. None of it is saved in the user's settings.
- **The stage is not rebuilt at every turn of the wheel.** Its size follows the camera's reach in steps (`stage.scale_step`, 1.5: each step a half larger than the last), so the mesh, the scene capture and the GI's acceleration structures are built when a step is crossed, not while zooming. The facets are finer (`facet` 200, `floor_step` 300, `wall_step` 400).

- **The lighting no longer changes from run to run (2026-11-27).** The stage was captured for ray tracing and shadows (`scene_capture.c`) with the game's `RotMatrixYXZ_gte` for each group, and rood-studio's host (`rood_studio_host.c`) stubs that function with one that returns the matrix without writing it: the matrix was whatever the stack held, so each run captured the stage's triangles at a different size and turn (the bounds of a 900-unit stage came out as +-15000) and the sun's shadows fell on that. The group's matrix is now built in `scene_capture.c` (`rotation_yxz`) without the game's routine, GTE or sine table: the table is round(4096 sin(a)) (each of its 4096 values equals the one in the executable), each GPF is (IR0 x IRn) >> 12 held to 16 bits. Against the game's routine, in the game: every angle of each axis and 4 million random turns (4,036,864 matrices, 0 different), and every group of the rooms the `--rooms` lane visits (12 rooms, 24 games; their groups all have no turn). The GTE's registers are per thread (`gte_scratch`, `__thread`), so no thread can disturb another's. Two things this showed: the stage's flat triangles were also taken as textured (the page-0 texel at VRAM (0, 0), the frame buffer, decided their colour and whether rays pass: `vk_rt.inc`, `vk_probes.inc`), and with the stage solid the wall at 1600 shadows the whole floor from a sun 40 degrees up (the in-game studio's floor was lit only because its triangles were see-through to rays by that texel), so the neutral look's sun is 65 degrees up. Proof: the same view 4 times, `ROOD_GI=0`: mean difference 0.0 of 255; with GI 0.0 to 0.55 (the denoiser); 3 times at 1080p 0.0 to 0.014.

## Known limits

- The stage is a room-format block (so ray tracing, probes and shadows see it). Its black facets of the first build were the old room's texture effects: their per-frame handlers (`vs_field_textureEffectCount` slots, BATTLE 2842C.c) wrote UV bytes at the old room's polygon offsets, and in the stage's layout those bytes are vertex words, which the native room mesh re-decoded (`mesh_follow`) into holes and slivers; `scene_dump` is captured before the writes, so it looked clean. The studio zeroes the count when it builds the stage; the render's rewind puts it back. `studio_smoke` checks 0 black pixels over 15 views and that the room's effects are back after leaving.
- Animations are not scrubbed or chosen yet (P7): every render replays from M, so a model shows the pose of the same few ticks.
- Names: enemies have theirs; characters and weapons are named by their id.

## The texel locator (Aseprite and the studio, both ways)

Code: `pc/src/studio_locate.cpp` (the maths: no game, no ImGui), `studio.cpp` (capture, marker, cursor, RPC), `render.c render_mesh_posed` (the posed triangles of a drawn model), `pc/tools/paint_live.py` (the bridge) and `pc/tools/aseprite/rood-live/rood-live.lua` (the extension, 1.4.0). Proof: `pc/tests/studio_locate_smoke.py` (the game), `pc/tests/aseprite_test.py` and `aseprite_extension_test.lua` (the bridge and the extension without Aseprite or the game).

### What Aseprite's Lua API can report (the spike; read from the API docs, github.com/aseprite/api, and tried against the installed Aseprite 1.3.18)

- Hover is possible, by polling. There is no mouse-move event (`app.events` has `sitechange`, `beforecommand`, `aftercommand`, `fgcolorchange`, `bgcolorchange`; `sprite.events` has `change`, `filenamechange`; a `Dialog` canvas gets mouse events only over the dialog's own canvas, not the sprite's). But `app.editor` (the active editor; nil in batch mode `-b`) has read-only `spritePos` (the sprite pixel under the cursor: "the pixel that will change if the user clicks") and `mousePos`, and read/write `scroll` (the sprite pixel the view is centred on) and `zoom`. A `Timer` (50 ms) reading `spritePos` is the hover. It has no event for entering or leaving the canvas, so the extension sends only a position inside the canvas that changed.
- Selecting a texel: `sprite.selection:select(Rectangle(x, y, 1, 1))` (tried in batch mode). Scrolling: `app.editor.scroll = {x = x + 0.5, y = y + 0.5}`. Making another open sprite the active one: `app.sprite = sprite`.
- Not needed, but there if hover is ever too much: `app.editor:askPoint{...}` (a modal click on the canvas, `onclick`/`onchange`/`oncancel`), `app.events:on("fgcolorchange")` (the eyedropper), `sprite.events:on("change")`, a selection read from `sprite.selection`, and a custom tool is not scriptable. The hover is switchable (`Rood live: locate hover on/off`; preference `hover`).

### Aseprite to the studio

The extension sends the cursor's pixel as text (`{"locate":{"material": sprite title, "x", "y"}}`) over the live-paint link. The bridge turns the page pixel into the texture it is in (`seed.json` slices: a model's page is boxes of textures, each with its content key; a room texture is the sprite itself) and the place in it, and calls RPC `studio locate {key, x, y}`. The studio finds the texture's uses in the picture (`emissive::use_list`: the page, palette and box it sits at in this picture, which is not the page the sprite was exported from: a model follows its texture slot), turns the texel into a page texel, and `studio_locate::locate` finds every triangle whose texture coordinates cover it: the texel's square is cut out of the triangle in texture space (Sutherland-Hodgman) and carried back onto the posed triangle by barycentres, so the footprint is the texel's exact shape on the surface, per triangle (shared or mirrored coordinates: several footprints). The marker is drawn over the picture by `pc_studio_overlay` (the ImGui foreground, so it is in `present_dump` and a screenshot): the footprint filled and outlined, a ring and a crosshair at its centre, pulsing; where the surface faces away or something is in front, `back_alpha` of it.

### The studio to Aseprite

The cursor over the model (`locate.pick_on`: `hover`, `click` or `off`) picks the texel under it: the nearest triangle at the pixel (the perspective-correct barycentre of its corners' texture coordinates). The reply names the page and palette texel and the texture's key and place in it; the bridge polls RPC `studio picked` (0.1 s), turns the key and place into the sprite title and pixel (the model's own page when several have the texture) and sends `{"select": {...}}`. The extension selects the pixel and, for a click (`locate.click_scrolls`), scrolls the view to it. A hover only selects.

### RPC

`studio {action: locate, key|label|page(+clut), x, y}` (or `clear: true`): the footprints (polygon, centre, window pixel, visible, area), the texture count and the triangle count. `{action: pick, x, y, tell}`: the texel under the window pixel (`tell`, default true, leaves it as the studio's pick for the bridge). `{action: picked}`: the studio's last pick with a serial that grows. `state` gains `capture` (triangles, meshes, whether the picture's capture is valid).

### Data (`locate` in studio.json)

`pick_on`, `click_scrolls`, `occlusion_tolerance` (a fraction of the camera distance), `marker` (the Aseprite cursor's: `color`, `fill_alpha`, `outline_alpha`, `line_width`, `ring_radius`, `ring_width`, `crosshair`, `pulse_hz` (0: steady), `pulse_depth`, `back_alpha`) and `pick` (the studio cursor's own texel, the same members, and `show`). The Studio window lists them like the rest.

### How it holds still

Each render that lands leaves the model's posed triangles and the view the picture was drawn with, only when no change is waiting (a camera change, a re-frame): the marker and the pick agree with the picture on screen to the pixel. While a camera change renders the marker is not drawn (the picture still shows the old view and the new view is not on screen yet); when the picture lands it is at the new place. A running turntable captures every render, so the marker follows the model. Nothing of this touches the game: the overlay is drawn only while the studio is entered, and the studio's leaving gives the game back as before.

### Limits

- Hidden-ness is the CPU's: a footprint is dimmed where another triangle of the model is nearer at its centre (`occlusion_tolerance`), not per pixel of the footprint, and not behind the stage.
- A texel is its page's pixel (palette indices are not looked at): two palettes of one texture are two pages, and the sprite titles name the palette (`_c<clut>`).
- The marker marks the posed model of the last render; models not drawn through the object builders (none in the studio) are not captured.

## rood-studio, the same studio with no game

`rood-studio` (the game binary started under that name; design and proof: `pc/docs/plans/2026-11-24-standalone-studio-design.md`) is this studio's code with no game behind it: the models are read from the disc by native decoders (`pc/src/native_model`), the stage and the look are the data above, and the Studio window's controls and catalog are its own screen (`studio.cpp` app mode: `pc_studio_app_*`). RPC `studio` works on it as it does in the game (`enter` and `leave` do nothing), with `animation {id, time, play, speed}` for the model's sequences. `pc/tests/rood_studio_smoke.py` compares it with this studio: the polygons, texture and CLUT words, content keys, bone matrices (the sequence decoder's, for the idle and other animations) and the pictures.

## Smooth animation (rood-studio)

`animation.smooth` (data, default on; the Studio window's "Smooth" box): the model's pose is shown at the time between the game's steps, not only at whole frames. The player's poses at the two steps around the time (`pc_nm_anim_play`, kept so only the next step is played as time goes on; a loop's end carries on from frame 1) are mixed by `pc_nm_pose_mix`: each bone's turn is a quaternion slerp (shortest way, so bones keep their lengths), the chain's scales, the root's place and offset are linear. At a whole frame the pose is the player's exactly (the frame slider and RPC `animation {time}` take fractions). Off, the game's own 30 (tickspeed 2) or 15 poses a second. A change of animation fades the shown pose into the new one over `animation.smooth_blend` frames (real time, 0: a cut). The in-game studio has no animation player (its models stand at the held frame), so there is nothing to smooth there. Proof: `rood-studio --check-smooth ENEMY ANIMATION` (run by `rood_studio_smoke.py`): whole steps exact, turns between and at the fraction, bone lengths kept; and the app's pictures at frame 10 and 10.5.
