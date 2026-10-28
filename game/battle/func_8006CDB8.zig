//! Forwards to func_8009D854 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8006CDB8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_8009D854 with the same argument.
pub fn func_8006CDB8(arg0: c_int) callconv(.c) void {
    c.func_8009D854(arg0);
}
