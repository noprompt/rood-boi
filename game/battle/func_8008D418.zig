//! Room section B's packed word, from its fields 52 and 54 (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: func_8008D418 (src/BATTLE/BATTLE.PRG/146C.c)
/// Packs the room's section B fields unk52 (high half) and unk54 (low half) into one int.
pub fn func_8008D418() callconv(.c) c_int {
    const section_b = psx.get(v.g.vs_battle_roomData().sectionB).?;
    return (@as(c_int, section_b.unk52) << 0x10) | @as(c_int, section_b.unk54);
}
