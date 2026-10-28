//! Battle unit 146C: stores a single value in the global D_800F1A20.
const v = @import("views_146C");

/// orig: func_8007DE38 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores `arg0` in the global D_800F1A20.
pub fn func_8007DE38(arg0: c_int) callconv(.c) void {
    v.g.D_800F1A20().* = arg0;
}
