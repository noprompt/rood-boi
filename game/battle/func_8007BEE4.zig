//! Forwards to func_800CF48C and returns its result (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007BEE4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the result of func_800CF48C.
pub fn func_8007BEE4() callconv(.c) c_int {
    return c.func_800CF48C();
}
