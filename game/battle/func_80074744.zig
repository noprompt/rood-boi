//! Battle camera step: raises the projection-distance flag and ends a finished camera transition (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80074744 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets flag 2 of the mode word when the projection distance exceeds 272, then ends the camera transition once it has stepped to completion.
pub fn func_80074744() callconv(.c) void {
    if (v.g.vs_main_projectionDistance().* > 272) {
        c.func_800A087C(0, psx.conv(c_int, c.func_800A0BE0(0) | 2));
    }
    if (c._stepCameraTransition() != 0) {
        c._endBattleCameraTransition();
    }
}
