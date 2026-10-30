//! Returns the battle global D_800F1B98 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DE68 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the current value of the battle global D_800F1B98.
pub fn func_8007DE68() callconv(.c) c_int {
    return v.g.D_800F1B98().*;
}
