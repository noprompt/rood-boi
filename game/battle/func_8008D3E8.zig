//! Room section B's workshop-related byte: the value at unk31 (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8008D3E8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns byte unk31 of the current room's section B.
pub fn func_8008D3E8() callconv(.c) c_int {
    const room = v.g.vs_battle_roomData();
    const section_b = psx.get(room.sectionB).?;
    return @as(c_int, section_b.unk31);
}
