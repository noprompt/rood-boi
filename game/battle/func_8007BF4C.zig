//! Battle unit 146C: forwards to func_8008ABB8 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007BF4C (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_8008ABB8 with 0 and discards its result.
pub fn func_8007BF4C() callconv(.c) void {
    _ = c.func_8008ABB8(0);
}
