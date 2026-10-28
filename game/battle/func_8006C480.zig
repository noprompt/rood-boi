//! Forwards to func_800CF7A8 with two zero arguments (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8006C480 (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_800CF7A8 with its two arguments, then two zeros.
pub fn func_8006C480(arg0: c_int, arg1: c_int) callconv(.c) void {
    c.func_800CF7A8(arg0, arg1, 0, 0);
}
