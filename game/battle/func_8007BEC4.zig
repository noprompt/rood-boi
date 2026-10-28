//! Forwards its argument to func_800CEF74 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007BEC4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Forwards `arg0` to func_800CEF74 and discards its result.
pub fn func_8007BEC4(arg0: c_int) callconv(.c) void {
    _ = c.func_800CEF74(arg0);
}
