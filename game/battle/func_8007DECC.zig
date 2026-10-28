//! Copies the D_800F1A68 block into the caller's buffer (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DECC (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the global D_800F1A68 block into the caller's struct.
pub fn func_8007DECC(arg0: ?*v.D_800F1A68_t) callconv(.c) void {
    arg0.?.* = v.g.D_800F1A68().*;
}
