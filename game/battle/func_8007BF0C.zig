//! Battle wrapper that reports whether the C helper func_800CEEBC returns nonzero (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007BF0C (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when func_800CEEBC returns nonzero, else 0.
pub fn func_8007BF0C() callconv(.c) c_int {
    return @as(c_int, @intFromBool(c.func_800CEEBC() != 0));
}
