//! Returns the battle global D_800F1A20 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DF10 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the value of D_800F1A20.
pub fn func_8007DF10() callconv(.c) c_int {
    return v.g.D_800F1A20().*;
}
