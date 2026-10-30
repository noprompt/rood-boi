//! Picks the random spawn values for a room record from the room's section B
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008FA14 (src/BATTLE/BATTLE.PRG/146C.c)
/// Fills a spawn record with two coordinates scattered over the room's section B ranges, a 512-step offset and a value in 8..23.
pub fn func_8008FA14(arg0: ?*v.D_800F1DD4_t) callconv(.c) void {
    const sectionB = psx.get(v.g.vs_battle_roomData().sectionB).?;
    const out = arg0.?;

    out.unk0 = psx.conv(i16, @as(c_int, sectionB.unk48[0].s16[0]) +% @rem(c.rand(), @as(c_int, sectionB.unk48[1].s16[0])));
    out.unk4 = psx.conv(i16, @as(c_int, sectionB.unk48[0].s16[1]) +% @rem(c.rand(), @as(c_int, sectionB.unk48[1].s16[1])));
    out.unk2 = psx.conv(i16, @rem(c.rand(), 512) +% 0x200);
    out.unkC = 0;
    out.unkF = psx.conv(u8, (c.rand() & 0xF) +% 8);
}
