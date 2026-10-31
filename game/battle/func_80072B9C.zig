//! Clears the camera mode global (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_80072B9C (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the camera mode to 0.
pub fn func_80072B9C() callconv(.c) void {
    v.g._cameraMode().* = 0;
}
