//! Battle helper wrapper: calls func_8008C49C with -1 as its second argument (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8008C518 (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_8008C49C with `arg0` and -1, discarding its result.
pub fn func_8008C518(arg0: c_int) callconv(.c) void {
    _ = c.func_8008C49C(arg0, -1);
}
