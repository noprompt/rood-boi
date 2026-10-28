//! Battle helper wrapper: forwards its argument to func_8009CC20 with flag 1
//! (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007CBBC (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_8009CC20 with the given value and the flag 1, discarding its result.
pub fn func_8007CBBC(arg0: c_int) callconv(.c) void {
    _ = c.func_8009CC20(arg0, 1);
}
