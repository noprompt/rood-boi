//! Returns a battle global word (pc/src/game/BATTLE/BATTLE.PRG/6F014.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_6F014");

/// orig: func_800D8044 (pc/src/game/BATTLE/BATTLE.PRG/6F014.c)
/// Returns the word held in global D_800F5680.
pub fn func_800D8044() callconv(.c) c_uint {
    return v.g.D_800F5680().*;
}
