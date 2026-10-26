//! Copies a P_CODE value into the global D_800F1A78 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DDD4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores the P_CODE at `arg0` into the global D_800F1A78.
pub fn func_8007DDD4(arg0: ?*v.P_CODE) callconv(.c) void {
    v.g.D_800F1A78().* = arg0.?.*;
}
