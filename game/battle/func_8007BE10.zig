//! Stores a value in the battle global D_800F18B0 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007BE10 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores its argument in D_800F18B0 and returns it.
pub fn func_8007BE10(arg0: c_int) callconv(.c) c_int {
    v.g.D_800F18B0().* = arg0;
    return arg0;
}
