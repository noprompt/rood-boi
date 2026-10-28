//! Resets the camera mode and runs the battle camera follow-up (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007B4C4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the camera mode to 2, runs the camera update, and calls the follow-up when D_800F1864 is set.
pub fn func_8007B4C4() callconv(.c) void {
    v.g._cameraMode().* = 2;
    c.func_8007B470();
    if (v.g.D_800F1864().* != 0) {
        c.func_8009E5C4(0);
    }
}
