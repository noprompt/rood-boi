//! Battle unit 146C: a one-call wrapper around func_8008AB80 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007BF2C (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_8008AB80 with 0 and discards its result.
pub fn func_8007BF2C() callconv(.c) void {
    _ = c.func_8008AB80(0);
}
