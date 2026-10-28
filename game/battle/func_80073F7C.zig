//! Sets up the battle room section, the camera mode, the per-slot state and the
//! opening scene message (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80073F7C (src/BATTLE/BATTLE.PRG/146C.c)
/// Starts a battle on room section `section` with source pose `source` and `arg2`, and shows the opening message when the information setting is on.
pub fn func_80073F7C(section: ?*v._mpdRoomSectionA, source: ?*v.func_8006EBF8_t3, arg2: c_int) callconv(.c) void {
    v.g.D_800F196C().* = 8;
    v.g._cameraMode().* = 1;
    _ = c.func_8006EF10();
    psx.put(&v.g.D_800F1910().unk0, section);
    v.g.D_800F1910().unk4.unk0 = source.?.*;
    v.g.D_800F1910().unk4.unkC = arg2;
    for (0..16) |i| {
        c.func_8009E5C4(@intCast(i));
    }
    if (v.g.vs_main_settings().information != 0) {
        c.vs_battle_displaySceneMessage(0xB, @as(c_int, section.?.unk0.unk6) +% 6, 1);
    }
    v.g.D_800F19CC().*.?.unk4 = 0;
    v.g.D_800F19CC().*.?.unk8.actionIndex = 0;
}
