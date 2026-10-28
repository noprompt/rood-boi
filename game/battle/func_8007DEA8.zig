//! Copies the battle's shared P_CODE value into the caller's record (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DEA8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores the shared P_CODE value D_800F1A78 into `out`.
pub fn func_8007DEA8(out: ?*v.P_CODE) callconv(.c) void {
    const dst = out.?;
    dst.* = v.g.D_800F1A78().*;
}
