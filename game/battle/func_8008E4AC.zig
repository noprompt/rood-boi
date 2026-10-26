//! Room section B lookup for the battle room (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: func_8008E4AC (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the unk56 field of the battle room's section B.
pub fn func_8008E4AC() callconv(.c) c_short {
    return psx.get(v.g.vs_battle_roomData().sectionB).?.unk56;
}
