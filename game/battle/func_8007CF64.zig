//! Battle actor lookup by slot (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8007CF64 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the battle actor held in slot `actorId` of `vs_battle_actors` (null when the slot is empty).
pub fn func_8007CF64(actorId: c_int) callconv(.c) ?*v.vs_battle_actor {
    // No bounds check: the C indexes the table unchecked, and psx.at does the same.
    return psx.at(v.g.vs_battle_actors(), actorId).*;
}
