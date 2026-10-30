//! Chooses a random start position for a battle actor from the room's section B data (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80090A1C (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets a random position and facing for `arg0` within the room's section B bounds, or the full 4096 range without them.
pub fn func_80090A1C(arg0: ?*v.D_800F1DD4_t) callconv(.c) void {
    const out = arg0.?;
    const section = psx.get(v.g.vs_battle_roomData().sectionB);
    if (section) |s| {
        const base0: c_int = s.unk48[0].s16[0];
        const span0: c_int = s.unk48[1].s16[0];
        out.unk0 = psx.conv(i16, base0 +% @rem(c.rand(), span0));

        const base1: c_int = s.unk48[0].s16[1];
        const span1: c_int = s.unk48[1].s16[1];
        out.unk4 = psx.conv(i16, base1 +% @rem(c.rand(), span1));
    } else {
        out.unk0 = psx.conv(i16, @rem(c.rand(), 4096));
        out.unk4 = psx.conv(i16, @rem(c.rand(), 4096));
    }
    out.unk2 = psx.conv(i16, @rem(c.rand(), 512) -% 2560);
    out.unkE = 2;
    out.unkC = 0;
    out.unkD = 0;
    out.unkF = psx.conv(u8, c.rand() & 0x7F);
}
