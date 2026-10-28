//! Forwards its two arguments to func_80069DEC (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007BBB8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Forwards its two arguments unchanged to func_80069DEC.
pub fn func_8007BBB8(arg0: c_int, arg1: c_int) callconv(.c) void {
    c.func_80069DEC(arg0, arg1);
}
