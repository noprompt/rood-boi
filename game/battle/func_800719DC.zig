//! Battle unit 146C: forwards to func_80070F28 with 0 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_800719DC (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_80070F28 with 0; its argument is unused.
pub fn func_800719DC(_: c_int) callconv(.c) void {
    c.func_80070F28(0);
}
