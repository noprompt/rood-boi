//! Empty object-data slot lookup for the battle unit 146C (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007CCAC (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the index of an empty object-data slot, as vs_battle_getEmptyObjectDataSlot does.
pub fn func_8007CCAC() callconv(.c) c_int {
    return c.vs_battle_getEmptyObjectDataSlot();
}
