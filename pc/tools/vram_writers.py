#!/usr/bin/env python3
"""The VRAM writer inventory (native renderer plan, step K0): every site in the game and the engine that puts pixels into the 1024 x 512
array or reads them out of it, by function, with what it moves, how often, and the step of pc/docs/plans/2026-11-27-native-renderer.md
that takes it over.

    python3 pc/tools/vram_writers.py            the table (markdown), what pc/docs/plans/2026-11-27-vram-writers.md holds
    python3 pc/tools/vram_writers.py --check    exit 1 when a site's function is not classified here (a new writer needs a line in WHO), or a
                                                classified function no longer has a site

The sites are the calls of LoadImage, LoadImage2, StoreImage, ClearImage, MoveImage, vs_main_loadClut (the CLUT stager: vs_main_commitClut
uploads its rows) and pc_frame_move (a copy item) in `game/` and `pc/src/`, found by reading the source (comments left out), and the host
modules that call pc_vram_transfer or pc_vram_clear (HOSTS). The classification is by reading each function.
"""
import argparse
import collections
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CALL = re.compile(r"\b(LoadImage2?|StoreImage|ClearImage|MoveImage2?|vs_main_loadClut|pc_frame_move)\b\s*\(")
FUNC_C = re.compile(r"^[A-Za-z_][\w\s\*]*?\b([A-Za-z_]\w*)\s*\([^;]*$")
FUNC_Z = re.compile(r"^\s*(?:pub\s+)?fn\s+(\w+)\s*\(")
SKIP_FILES = ("libgpu", "pc/src/boot_sdk.c", "pc/src/third_party")
# cadence: once (a load), event (a state change, an effect starting), step (every game step while it runs), frame (a movie's frame)
# what: the target; step: the plan step that takes it over (K3 models, K4 rooms and palettes, K6 sheets and text, K7 snapshots, K8 movies)
WHO = {
    # models
    "parseShp": ("model palettes and texture at the loader (SHP)", "once", "K3"),
    "loadMaterialPalette": ("a material's palette", "once", "K3"),
    "vs_actors_enableModelPalettePulse": ("model palette, colour pulse started", "event", "K4 live palette"),
    "vs_actors_updatePalettePulse": ("model palette, colour pulse", "step", "K4 live palette"),
    "vs_actors_updateActorAppearanceTransition": ("actor palette, appearance transition (fade, flash)", "step", "K4 live palette"),
    "vs_field_setPlatformFreezeAppearance": ("platform palette, frozen look", "event", "K4 live palette"),
    "vs_actors_textureFrameMove": ("actor texture-map frame copy", "step", "K4 frame or image op"),
    "vs_actors_textureOverlayMove": ("actor texture overlay copy", "step", "K4 frame or image op"),
    "vs_actors_stepTextureScrolling": ("actor texture scroll", "step", "K4 frame or image op"),
    "func_800AACDC": ("actor texture-map frames (DR_MOVE items)", "step", "K4 frame or image op"),
    "vs_render_queueTextureRectangleMove": ("a texture rectangle copy queued by the draw code", "step", "K4 frame or image op"),
    # rooms
    "vs_field_uploadRoomPalettes": ("the room's three 256-colour palettes and the gimmick palette block", "once", "K4"),
    "vs_field_finishTiledBackgroundLoad": ("the room backdrop's tiles and palette", "once", "K4"),
    "vs_field_animateRoomTextureImages": ("room texture effect type 1: atlas frames and scrolls (MoveImage)", "step", "K4 frame index"),
    "vs_field_drawRoomTriggerMarkers": ("trigger marker texture frames (MoveImage)", "step", "K4 frame index"),
    "vs_field_createGimmickInstance": ("a gimmick's palette", "event", "K4 live palette"),
    "vs_render_updateGimImageSet": ("a GIM image set's palette", "step", "K4 live palette"),
    "loadZndTims": ("a zone's TIM pack: palette rows and textures", "once", "K4"),
    # effects and dynamic images
    "loadEtm": ("effect textures (ETM)", "once", "K6 sheets"),
    "vs_effects_updateEffectTextureLoading": ("an effect's texture as it starts", "event", "K6 sheets"),
    "renderImage": ("an image drawn into VRAM as a texture (dynamic)", "event", "K6 dynamic image"),
    "renderTextImmediate": ("glyph cells read back (StoreImage), dynamic text", "event", "K6 typed text"),
    "vs_render_blendGlyphIntoPixels": ("glyph pixels read back, dynamic text", "event", "K6 typed text"),
    "_loadSystemDat": ("the battle's system textures: HUD sheets, fonts, palettes", "once", "K6 sheets"),
    # menus, title, ending
    "vs_ending_creditsInitializeDisplay": ("the credits' display cleared", "once", "K6 sheets"),
    "vs_ending_creditsUploadTexture": ("a credits texture", "event", "K6 sheets"),
    "vs_ending_loadClearResultsStep": ("the results screen's textures", "event", "K6 sheets"),
    "vs_mainMenu_unpackMenubg": ("the main menu's background and palette", "once", "K6 sheets"),
    "_loadMapBackground": ("the map's background palette", "once", "K6 sheets"),
    "vs_menu5_exec": ("the map screen's clears and palette", "event", "K6 sheets"),
    "_renderImage": ("MENU7's images drawn into VRAM (dynamic)", "event", "K6 dynamic image"),
    "vs_menu7_dataMenu": ("the data menu cleared", "event", "K6 sheets"),
    "vs_menu7_gameOver": ("the game over screen's clear and palette", "event", "K6 sheets"),
    "_copyCluts": ("the manual's palettes", "once", "K6 sheets"),
    "_copySprites": ("the manual's sprites", "once", "K6 sheets"),
    "_initCongratulationsScreen": ("MENUF puzzle screen sheets", "once", "K6 sheets"),
    "_initCubePuzzleQuit": ("MENUF puzzle screen sheets", "once", "K6 sheets"),
    "_initCubePuzzleStart": ("MENUF puzzle screen sheets", "once", "K6 sheets"),
    "_initTimeAttackEnd": ("MENUF time attack sheets", "once", "K6 sheets"),
    "_initTimeAttackStart": ("MENUF time attack sheets", "once", "K6 sheets"),
    "_pulseCubePuzzleEnd": ("MENUF palette pulse (a blended palette uploaded each step)", "step", "K4 live palette"),
    "_pulseTimeAttackEnd": ("MENUF palette pulse (a blended palette uploaded each step)", "step", "K4 live palette"),
    "_bufferLoadingScreen": ("the loading screen's picture", "event", "K6 sheets"),
    "_displayLoadingScreen": ("the loading screen's picture", "event", "K6 sheets"),
    "_sysReinit": ("VRAM cleared at a system restart", "event", "K9"),
    "vs_main_commitClut": ("the CLUT stager's rows to VRAM (every vs_main_loadClut ends here)", "step", "K4 palettes"),
    "vs_main_loadClut": ("the CLUT stager: one palette into the staging array", "step", "K4 palettes"),
    "vs_main_loadClutTransition": ("a palette transition through the stager", "step", "K4 live palette"),
    "_copyTitleBgData": ("the title's background", "once", "K6 sheets"),
    "_decDCToutCallback": ("a movie's decoded frame (MDEC output)", "frame", "K8"),
    "_displayPublisherAndDeveloper": ("the publisher screens cleared", "event", "K6 sheets"),
    "_drawImage": ("the title's images", "event", "K6 sheets"),
    "_fadeInMenuCopyright": ("the title's copyright line: a picture blended in a buffer each step (a fade) and uploaded", "step", "K1 typed fade over a sheet"),
    "_fadeInMenu": ("the title menu's picture: blended in a buffer each step (a fade) and uploaded", "step", "K1 typed fade over a sheet"),
    "_gameLoadScreen": ("the load screen cleared", "event", "K6 sheets"),
    "_gameSaveScreen": ("the save screen cleared", "event", "K6 sheets"),
    "_getNextMovieFrame": ("a movie frame's area cleared", "frame", "K8"),
    "_initSaveScreen": ("the save screen cleared", "event", "K6 sheets"),
    "_initScreen": ("the title screen cleared", "event", "K6 sheets"),
    "_setMenuItemClut": ("a title menu item's palette, two palettes blended by a factor each step", "step", "K4 live palette"),
    # the copy item itself and its header
    "pc_frame_move": ("the copy item's definition", "-", "K2 / K7"),
    "?": ("pc_frame_move's declaration and the packets' copies", "-", "K2 / K7"),
}
# Host modules that move pixels with pc_vram_transfer / pc_vram_clear (not the game's calls).
HOSTS = [
    ("pc/src/boot_runtime.c", "the walk's LoadImage, MoveImage, fill and copy commands, the MDEC movie frames, StoreImage (pc_vram_transfer)", "all", "K9"),
    ("pc/src/hud/hud_bridge.c", "the classic claims' cells: reads (1902) and writes (2113, 2193) of rectangles the claim draws", "event", "K6"),
    ("pc/src/classic/classic_parity.c", "held uploads replayed for the parity check (847)", "test", "K9"),
    ("pc/src/dev_rpc.c", "RPC texture write for tests (4781)", "test", "K9"),
    ("pc/src/native_model/native_model.c", "the studio's decoded texture and palette put into VRAM (496)", "once", "K3"),
    ("pc/src/rood_studio.c", "the studio's backdrop (pc_vram_clear, 284)", "once", "K3"),
    ("pc/src/snapshot.c / state_rewind.c / photo.cpp / engine_reload.c", "a whole-array resync (pc_hw_resync) after a state is loaded", "event", "K9 (save states)"),
]


def sites():
    found = []
    for tree, suffixes in (("pc/src", {".c", ".h", ".cpp", ".inc"}), ("game", {".c", ".h", ".zig"})):
        for path in sorted((ROOT / tree).rglob("*")):
            name = path.relative_to(ROOT).as_posix()
            if path.suffix not in suffixes or not path.is_file() or any(s in name for s in SKIP_FILES):
                continue
            func = "?"
            for number, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
                stripped = line.lstrip()
                if stripped.startswith(("//", "/*", "*")):
                    continue
                if path.suffix == ".zig":
                    m = FUNC_Z.match(line)
                elif line and not line[0].isspace() and not line.startswith(("#", "}", "typedef", "extern", "static const")) and "=" not in line and ";" not in line:
                    m = FUNC_C.match(line)
                else:
                    m = None
                if m:
                    func = m.group(1)
                c = CALL.search(line)
                if c:
                    found.append((name, number, func, c.group(1)))
    return found


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    found = sites()
    by_func = collections.defaultdict(list)
    for name, number, func, call in found:
        by_func[(name, func)].append((number, call))
    unclassified = sorted({func for (_, func) in by_func if func not in WHO})
    stale = sorted(f for f in WHO if f not in {func for (_, func) in by_func})
    if args.check:
        for func in unclassified:
            print(f"unclassified: {func} ({', '.join(sorted({n for (n, f) in by_func if f == func}))})")
        for func in stale:
            print(f"stale (no site): {func}")
        print(f"{len(found)} sites in {len(by_func)} functions; {len(unclassified)} unclassified, {len(stale)} stale")
        return 1 if unclassified or stale else 0
    cadence = collections.Counter()
    print("| file | function | calls | moves | cadence | taken over by |\n|---|---|---|---|---|---|")
    for (name, func), calls in sorted(by_func.items()):
        what, how, step = WHO.get(func, ("(unclassified)", "?", "?"))
        cadence[how] += len(calls)
        kinds = collections.Counter(c for _, c in calls)
        print(f"| {name} | {func} | {', '.join(f'{k} x{v}' if v > 1 else k for k, v in sorted(kinds.items()))} (line {', '.join(str(n) for n, _ in calls)}) | {what} | {how} | {step} |")
    print("\nHost modules:\n\n| file | what | cadence | taken over by |\n|---|---|---|---|")
    for name, what, how, step in HOSTS:
        print(f"| {name} | {what} | {how} | {step} |")
    print(f"\n{len(found)} sites in {len(by_func)} functions; by cadence: " + ", ".join(f"{k} {v}" for k, v in sorted(cadence.items())))
    return 0


if __name__ == "__main__":
    sys.exit(main())
