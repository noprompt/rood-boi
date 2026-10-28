//! Battle state helper: the low two bits of D_800F1868 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_80074294 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the low two bits of the global D_800F1868.
pub fn func_80074294() callconv(.c) c_int {
    return v.g.D_800F1868().* & 3;
}
