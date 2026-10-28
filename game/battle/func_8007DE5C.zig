//! Stores its argument in the global D_800F1A40 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DE5C (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores arg0 in the global D_800F1A40.
pub fn func_8007DE5C(arg0: c_int) callconv(.c) void {
    v.g.D_800F1A40().* = arg0;
}
