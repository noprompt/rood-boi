//! Returns the battle global D_800F18A8 (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_80089104 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Returns the battle global D_800F18A8.
pub fn func_80089104() callconv(.c) c_int {
    return v.g._zoneContext().musicId;
}
