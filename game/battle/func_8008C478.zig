//! Room data lookup: the section 7 offset of the battle room (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8008C478 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the battle room's section 7 offset plus 8 per arg0, or 0 when section 7 is absent.
pub fn func_8008C478(arg0: c_int) callconv(.c) c_int {
    const section7: c_int = v.g.vs_battle_roomData().section7;
    if (section7 != 0) {
        return section7 +% (arg0 *% 8);
    }
    return 0;
}
