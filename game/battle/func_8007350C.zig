//! Forwarder in the battle unit 146C (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007350C (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_8006F5CC and returns.
pub fn func_8007350C() callconv(.c) void {
    c.func_8006F5CC();
}
