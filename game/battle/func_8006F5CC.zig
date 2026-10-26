//! Clears the camera mode and marks the room as seen (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8006F5CC (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets D_800F196C to 1, clears the camera mode and marks the room seen.
pub fn func_8006F5CC() callconv(.c) void {
    v.g.D_800F196C().* = 1;
    v.g._cameraMode().* = 0;
    c._setRoomSeen();
}
