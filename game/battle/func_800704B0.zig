//! The action's flash phase entered (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");
const v = @import("views_146C");

/// orig: func_800704B0 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Sets the camera mode (the action phase) to 6 and clears D_800F522C (func_800CF920).
pub fn func_800704B0() callconv(.c) void {
    v.g._cameraMode().* = 6;
    c.func_800CF920();
}
