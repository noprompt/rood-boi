//! Forwards its argument to func_8009D208 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007CC4C (src/BATTLE/BATTLE.PRG/146C.c)
/// Forwards its argument to func_8009D208.
pub fn func_8007CC4C(arg0: c_int) callconv(.c) void {
    _ = c.func_8009D208(arg0);
}
