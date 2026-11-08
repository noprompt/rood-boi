//! Returns the battle global D_800F1A40 (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DF30 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Returns the value of the battle global D_800F1A40.
pub fn func_8007DF30() callconv(.c) c_int {
    return v.g.D_800F1A40().*;
}
