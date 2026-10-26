//! Resets the battle's D_800F196C and camera mode, then calls func_8009E5C4 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8006F5FC (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets D_800F196C to 12, clears the camera mode and calls func_8009E5C4(0).
pub fn func_8006F5FC() callconv(.c) void {
    v.g.D_800F196C().* = 12;
    v.g._cameraMode().* = 0;
    c.func_8009E5C4(0);
}
