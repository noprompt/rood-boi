//! Stores a value in D_800F185C and calls func_8007B29C (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8006D028 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores `arg0` in D_800F185C, then calls func_8007B29C with 0xE, 8, `arg0`, 0x10, 0, 0.
pub fn func_8006D028(arg0: c_int) callconv(.c) void {
    v.g.D_800F185C().* = arg0;
    c.func_8007B29C(0xE, 8, arg0, 0x10, 0, 0);
}
