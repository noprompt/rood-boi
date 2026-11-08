//! Returns the battle global D_800F1B9C (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DF00 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Returns the value of the battle global D_800F1B9C.
pub fn func_8007DF00() callconv(.c) c_int {
    return v.g.D_800F1B9C().*;
}
