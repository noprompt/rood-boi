//! Battle room data accessor (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8008B6FC (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns section 6 of the battle room data.
pub fn func_8008B6FC() callconv(.c) c_int {
    return v.g.vs_battle_roomData().section6;
}
