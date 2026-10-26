//! Address of the battle table D_800F1D78 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8008EB24 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the address of the five-entry table D_800F1D78 (array decay).
pub fn func_8008EB24() callconv(.c) [*c]c_int {
    return @ptrCast(v.g.D_800F1D78());
}
