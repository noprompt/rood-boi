//! Workshop check for the current room (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: vs_battle_inWorkshop (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the current room's isWorkshop flag from its section B.
pub fn inWorkshop() callconv(.c) c_int {
    return @as(c_int, psx.get(v.g.vs_battle_roomData().sectionB).?.isWorkshop);
}
