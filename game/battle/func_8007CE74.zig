//! Sets the battle camera's spherical pitch (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007CE74 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the camera pitch to arg0 when arg0 is -0x300 or -0x80, otherwise to -0x180.
pub fn func_8007CE74(arg0: c_int) callconv(.c) void {
    const cam = v.g.vs_battle_cameraCurrentSpherical();
    if (arg0 == -0x300 or arg0 == -0x80) {
        cam.values.pitch = arg0;
        return;
    }
    cam.values.pitch = -0x180;
}
