//! Forwards to func_80089CE4 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007C404 (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_80089CE4 and returns.
pub fn func_8007C404() callconv(.c) void {
    c.func_80089CE4();
}
