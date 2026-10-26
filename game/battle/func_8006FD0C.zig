//! Sets the battle camera mode (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8006FD0C (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the camera mode to 9.
pub fn func_8006FD0C() callconv(.c) void {
    v.g._cameraMode().* = 9;
}
