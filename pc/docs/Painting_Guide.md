# Painting material maps for a model

This guide takes you from nothing to a painted model: summon a character, enemy or weapon in the game's model studio, paint how its surfaces look in Aseprite, or in PhotoCraft if you want layer masks (shiny or dull, metal or cloth, flat or raised) and watch the game show every stroke as you paint it.

You do not paint colour. The game's own texture stays as it is; you paint extra maps that tell the lighting how each pixel of it behaves.

## What you need

- The game built and running on your machine (see the main README), with your own copy of the disc.
- Aseprite 1.3 or later (tested with 1.3.18). Colour mode must be RGB, which the exported files already are.
- Python 3 with numpy and Pillow (the tools import them).
- Two terminals open in the repository's top folder.

Everything below is typed from that top folder.

## What the layers mean

Each model page you open in Aseprite has these layers, bottom to top:

| Layer | What you paint | How to read it |
| --- | --- | --- |
| Game colour (reference) | Nothing. It is the game's texture, locked, so you can see what you are painting on. | Do not edit it; changes are not imported. |
| Height | Relief: how much a pixel is raised or sunk. | Mid grey (128) is flat. Lighter is raised, darker is sunk. Hidden at first; click its eye to show it. |
| Metal | Whether a pixel is metal. | Black is not metal (cloth, skin, leather, wood). White is bare metal. |
| Roughness | How scattered the shine is. | White is rough and matte. Black is smooth and mirror-like. Hidden at first. |
| Material | A whole kind of material in one stroke (Polished steel, Worn steel, Dark iron, Rusted iron, Gold, Bronze / brass, Silver, Leather, Cloth, Stone, Wood, Skin). | One stroke sets metal and roughness together, from a swatch. Empty until you paint. |

A transparent pixel on any layer means "leave the game's own value here". Erase to go back to the game's value. Other channels, such as emission, will appear as new layers when the game supports them; the layers in your file are the ones that work today.

## Steps

### 1. Start the game

```
pc/run-game.sh --vulkan
```

Load a save and get into the game. The studio freezes the game where it is and gives it back unchanged when you leave.

### 2. Open the model studio and summon a model

1. Press Escape (or F1) to open the editor.
2. Choose Window > Studio. The window's top line says whether you are in the studio; click Enter the studio there. The game is held and a neutral grey stage appears, and the line then reads "In the studio" with a Leave button. The window has two columns: the controls on the left, the model list on the right, each scrolling on its own, so it works docked short and wide.
3. In the list on the right, pick a kind (All, Characters, Enemies or Weapons) and click a model (clicking one also enters the studio if you have not). Enemies have names; characters and weapons are listed by number.
4. In the controls on the left, click Frame the model if it is not centred.
5. The controls show the model's key in a line reading "Model key: ..." (with a Copy button). That key names what you are painting; the files you make carry it in their names.

The model now stands on the stage. Leave the studio open for the rest of the steps.

Screenshot: the studio with a character on the grey stage.

### Painting without the game: rood-studio

`pc/run-studio.sh` starts rood-studio, the same studio with no game behind it: no save to load, the models straight from the disc (`--character N`, `--enemy N`, `--weapon N` start with one). Its models are on the left, its controls on the right (the Studio window's, plus the Animation list, Play and Frame to pose the model); the pointer on the model orbits (drag) and zooms (wheel), F frames it. Steps 4 to 10 below are the same with the studio's socket, `pc/build/boot/rpc-studio.sock`, in place of the game's. The live link (step 5) paints into whichever of the studio and the game is running, or both at once: leave `rood-studio` open beside the game and a stroke shows in both, the studio's own pick and marker (step 8) working on the studio.

### 3. Install the Aseprite extension (once)

```
python3 pc/tools/aseprite/build_extension.py
```

It prints where it wrote `rood-live.aseprite-extension` and how to install it. Double-click that file, or in Aseprite use Edit > Preferences > Extensions > Add Extension, then restart Aseprite. If you installed an older Rood live before, remove it on the same page first.

### 4. Export the model to Aseprite

With the model still on the stage:

```
python3 pc/tools/paint_roundtrip.py paint model --game pc/build/boot/rpc-live.sock --model studio --painter aseprite
```

This reads the model the studio is showing and writes one Aseprite file per texture page into `pc/user/paint/model-<id>/aseprite/`, then opens them in Aseprite (when there are six or fewer) and starts the live link for them (step 5). The file names look like `m61c3d37af4_p10_c3b70.aseprite`: the model, the texture page and the palette. Some models have more than one page; paint each file.

The pages are 256 by 256 pixels, but the game's texture only fills part of each one. The rest shows as a checkerboard. Zoom in on the part with the texture.

### 5. The live link

`paint ... --painter aseprite` starts the live link itself, right after it opens Aseprite, and keeps running in that terminal, printing what it is doing (strokes, saves). Leave it there while you paint. It stops by itself when you close Aseprite, or with Ctrl+C. Its first line says what it is painting into: the studio's socket, the game's, or both (`--rpc SOCKET` names them yourself, once for each; the `--game` socket you exported from is always one; by default it also looks for `rpc-studio.sock` and `rpc-live.sock`). If it says the game is not running, your game was not started with `pc/run-game.sh`: pass its socket with `--game` or `--rpc <path>`.

If a live link is already running for the same package, `paint` uses it. If one is running for another package, `paint` says which and does not touch it: stop that one with Ctrl+C in its terminal, then start this package's by hand:

```
python3 pc/tools/paint_roundtrip.py live pc/user/paint/model-<id>
```

The same command starts the link when `paint` did not (`--no-live`, or more than six pages so Aseprite was not opened for you). `--port N` changes the port (also in Aseprite's Rood live preferences).

### 6. Connect Aseprite

1. Open the file in Aseprite if it is not open already.
2. The first time, Aseprite shows a Security window asking to let the script open a WebSocket connection to `ws://127.0.0.1:47480`. Click Allow to Open Connections. Tick Don't show this specific alert again if you do not want it each time.
3. A small window called Rood live appears. Its Game line should say the game is running. If it says the live link is not running, the link in step 5 is not up: it shows the command to start it. It lists the twelve material presets as buttons.

Screenshot: the Security window, then Aseprite with the layers panel and the Rood live window. The Rood live window opens at the right edge of the Aseprite window, out of the canvas's way. Drag it by its title bar if you want it elsewhere; Aseprite remembers where you left it.

If you cannot see the layers, open View > Timeline.

### 7. Paint

Zoom in so one pixel is several screen pixels. Use the pencil with a 1 pixel brush where you want exact pixels, or a larger brush for broad areas.

Two ways to paint:

- **A kind of material.** Click a preset in the Rood live window (for example Worn steel). That sets your colour to the preset's swatch and selects the Material layer. Paint with the pencil. One stroke sets how metal and how rough that area is.
- **One channel at a time.** Select the Metal, Roughness or Height layer, pick white, black or a grey, and paint. Show one channel at a time (click the eyes) so you can read it. A Metal or Roughness pixel you paint on top of a preset wins over the preset, so you can fine-tune.

Do not resize the canvas or rename layers. Extra layers of your own are ignored.

Each stroke reaches the game within a fraction of a second. Look at the studio to see it.

Screenshot: the Material layer painted with Polished steel over the part of the page the model uses.

### 8. Find a pixel on the model, and a model spot in Aseprite

This is the texel locator. It answers "where on the model is this pixel?" and "which pixel is this part of the model?".

- **Aseprite to the model.** Move the mouse over the canvas in Aseprite. A pink ring and crosshair appears on the model in the studio, with the exact pixel's shape outlined where it sits on the surface. Where that pixel is used in several places, it is marked in each. The marker is small at the studio's default distance; bring the camera closer to see it well. In the camera values under "Stage, camera and look values", a smaller zoom or `fov` number is closer.
- **The model to Aseprite.** Move the mouse over the model in the studio. A light blue marker shows the pixel under it and Aseprite selects that pixel. Click the model and Aseprite also scrolls to it. If you would rather it only reacts to clicks, change `locate.pick_on` to `click` in the studio's list of values (open "Stage, camera and look values"); `off` stops it.

If hovering in Aseprite gets in your way, switch it off with the command "Rood live: locate hover on/off" in File > Scripts.

Screenshots: the pink marker on the model while the mouse is over the page in Aseprite, and Aseprite with one pixel selected after clicking on the model.

### 9. Judge the material

Shine is hard to read against a busy stage. In the Studio window's controls (left column):

- **Backdrop.** The Backdrop black, Backdrop grey and Backdrop white buttons replace the stage with one flat colour. Backdrop: stage brings it back. The model is still lit the same way.
- **Turntable.** Under "Stage, camera and look values", the turntable group has `model` (the model turns) and `light` (the light goes round it), with speeds in degrees a second (negative turns the other way). Metal and rough surfaces change as the light moves across them, which is the quickest way to see whether your values are right. "Turntable: stop and reset" puts it back.
- **Look.** The Look drop-down chooses `neutral` (a key light and a sky, the usual) or `flat` (no light, the model's own colour).

Screenshots: the model on the grey and the black backdrop, and the model turned partway round.

### 10. Save

Press Ctrl+S in Aseprite. The status bar says the file is saved, and the live link's terminal prints a line such as `watch: 14:02:11 m61c3d37af4_p10_c3b70.aseprite: metal, roughness imported`. Saving keeps your paint in your own copy of the game: it is written as maps under `pc/user/lighting/materials/` with an entry in `pc/user/lighting/materials.json`, and the game picks them up straight away and after a restart. Nothing you paint changes the original game files.

Close the studio with Leave when you are done. The game goes back to exactly where it was.

### 11. Share what you made

Make a pack: one small file of only the pixels you painted.

```
python3 pc/tools/paint_roundtrip.py pack pc/user/paint/model-<id>
```

It writes `<model key>.roodpack.zip` into that folder and prints how many pages and painted pixels it holds. A pack has the model's key and your painted layers (Height, Metal, Roughness, Material). It does not contain the game's texture or the reference layer, only your strokes, so it is safe to share. Send the pack file, and say which studio entry it is for (its kind and name or number, as the studio's list showed it).

Send it by opening an issue on the project's GitHub page (Issues > New issue), titled "Pack: " and the studio entry, and attaching the `.roodpack.zip` file to it.

Do not send the .aseprite files themselves: they include a copy of the game's own texture.

### Using someone else's pack

Summon the same model in the studio, export it the same way (steps 2 and 4), then:

```
python3 pc/tools/paint_roundtrip.py unpack <the pack file> pc/user/paint/model-<id>
```

The strokes go into your Aseprite files and into your game, as if you had painted and saved them. A pack made for another model is refused, with a message saying what to export.

## Painting in PhotoCraft (layer masks, fill layers, blend modes)

[PhotoCraft](https://github.com/storytold/photocraft) is a Photoshop-like editor with real layer masks, so you can paint a region once and let a mask decide where it applies. It is a second painter beside Aseprite: the same maps, the same live link into the game, a different set of tools. Needs PhotoCraft 0.23 or later on the PATH (`photocraft`).

### Start

Run the same export as for Aseprite, with `--painter photocraft`, while the game is running (the model is the one summoned in the studio):

```
python3 pc/tools/paint_roundtrip.py paint model --model 7d3ede67 --game pc/build/boot/rpc-live.sock --painter photocraft
```

This writes one layered Photoshop file per texture page into `pc/user/paint/model-<id>/photocraft/` (`<texture>.psd`), starts a separate PhotoCraft with them open (your own PhotoCraft, if you have one open, is left alone), and runs the live link in that terminal. Leave the terminal running. It stops when you close the package's documents in PhotoCraft, when PhotoCraft quits, or with Ctrl+C. If a PhotoCraft started this way for the package is still open, the files open in it instead. `--photocraft-port N` picks the control port (default: the first free one from 47490). To start the link for a package that is already exported: `python3 pc/tools/paint_roundtrip.py photocraft pc/user/paint/model-<id>`.

PhotoCraft's control server listens on `127.0.0.1` only, with a token the tool keeps in `photocraft/.control-token` (mode 0600) and checks with a challenge that never sends it; PhotoCraft may read and write only that `photocraft/` folder.

### The layers

Each file has, bottom to top:

- **Game colour (reference)**: the game's texture, locked. Not imported.
- **Height**, **Metal**, **Roughness**: groups. Each holds one layer, "<name> from the game": the game's current map, grey and opaque where the game has a map and transparent where it has none (transparent means "the game's own value"). Paint inside the group. Height: 128 grey is flat, lighter is raised, darker is sunk. Metal: black is not metal, white is metal. Roughness: white is matte, black is mirror-like.

What the game gets for a channel is PhotoCraft's picture of that group alone, laid over the game's value: masks, fill layers, blend modes, layer opacity, feather and brush softness all count exactly as you see them. A pixel the group leaves transparent (or at the game's value) keeps the game's value; a half-transparent pixel is halfway to it. Which group is visible, and the group's own opacity, do not matter (the link draws each group at full strength); hide or delete layers inside a group to take them out.

The material presets are swatches: in the Swatches panel the group "Rood materials" has a grey swatch for each preset and channel it sets ("Worn steel: Metal 1.00", "Worn steel: Roughness 0.42"). A grey's value is the map's value. They are added once; a PhotoCraft that already has the group is left as it is (the values are in `pc/assets/materials/paint-presets.json`, and your own in `<lighting>/paint-presets.json`).

### Using masks

- **A region of worn steel.** Select the Metal group, add a Solid Color fill layer in it (the "Worn steel: Metal 1.00" swatch), and give the fill layer a mask: fill the mask black and paint white where the steel is (or make a selection and add the mask from it). Do the same in the Roughness group with the "Worn steel: Roughness 0.42" swatch, and share the mask by copying it (Alt-drag the mask onto the other layer), or paint both fill layers' masks from one selection saved as a channel. Change the swatch colour of the fill layer and the game follows.
- **Relief with a soft edge.** In the Height group add a layer filled 150 grey (a little raised) with a mask painted with a soft brush: the edge falls off smoothly.
- **Dirt and scuffs.** Paint with a soft grey brush on a new layer in Roughness; set the layer's opacity or blend mode (Multiply to only darken) as you like.
- **Back to the game's value.** Erase to transparent, or delete the layer.

### Save

Press Ctrl+S in PhotoCraft (keep the format Photoshop). The link prints `photocraft: <time> <file>.psd saved: metal, roughness imported`. The maps go into `pc/user/lighting/materials/` with a catalog entry, exactly as the Aseprite save does, and nothing is written until something differs from the game. `python3 pc/tools/paint_roundtrip.py import pc/user/paint/model-<id>` imports what the last save kept (the link keeps the maps as they were at each save in `photocraft/saved/`). Exporting again keeps your `.psd` files (delete one to start it again from the game's maps).

### Limits

- The link talks to PhotoCraft's control server, which has no change event: it looks at each document's revision four times a second and draws the groups about a third of a second after the last change. A map reaches the game after you finish a stroke, not during it.
- To draw a group the link makes a throwaway copy of the document for about a third of a second and closes it again; the tab flashes and your active document is made active again. Do not close tabs while it works.
- PhotoCraft answers the control server only while its window is drawing. A minimised or fully covered window (on Wayland) stops the link until the window is back; it says so and tries again, and the link ends only when PhotoCraft quits.
- A saved file can only be read back through PhotoCraft: keep the link running while you save. Saving with the link stopped keeps your layers but the maps are not imported until the file is opened and saved again with the link running.
- No Material preset layer and no texel locator (the pink ring and click-to-select of the Aseprite extension): the presets are swatches, and the link only moves maps.
- Do not resize the canvas or change its mode (8-bit RGB). The only channels are the ones the channel table has.

## If something goes wrong

- **The live link says the game is not running, or strokes do nothing.** The game has to be the one started by `pc/run-game.sh` (or pass its socket with `--rpc`), and the live link must still be running in its terminal (the one `paint` started; if you closed it, start it again with the `live` command of step 5). Its first line says "game reachable" when it found the game.
- **The export says the model is not drawn.** Summon it in the studio first and keep the studio open while you export.
- **Aseprite's Extensions page shows an old Rood live.** Remove it, then install the new file from step 3 and restart Aseprite.
- **Nothing is selected in Aseprite when you click the model.** The file for that texture page must be open. Models with several pages need each page's file open to react to clicks on it.
