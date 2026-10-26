//! The current battle scene id, read from the battle room's section B
//! (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: vs_battle_getCurrentSceneId (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the scene id of the current battle room, read from its section B.
pub fn getCurrentSceneId() callconv(.c) c_int {
    const section_b = psx.get(v.g.vs_battle_roomData().sectionB).?;
    return @as(c_int, section_b.sceneId);
}
