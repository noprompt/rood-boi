//! Forwards two arguments to func_800CF830 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8006C4A4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Forwards its two arguments unchanged to func_800CF830.
pub fn func_8006C4A4(arg0: c_int, arg1: c_int) callconv(.c) void {
    c.func_800CF830(arg0, arg1);
}
