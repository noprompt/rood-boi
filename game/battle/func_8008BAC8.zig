//! Collects the room's door sections that match a door key (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008BAC8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Fills D_800F1D08 with the room's door sections matching arg0/arg1/arg2 and returns it, or null when the room has no door section.
pub fn func_8008BAC8(arg0: c_int, arg1: c_int, arg2: c_int) callconv(.c) ?*v.D_800F1D08_t {
    const room = v.g.vs_battle_roomData();
    const first = psx.get(room.doorSection) orelse return null;

    const out = v.g.D_800F1D08();
    out.count = 0;
    const temp_s1: c_int = psx.conv(c_int, room.header.doorSectionLen / 12);

    v.g.vs_main_stateFlags().unkAC[7] = psx.conv(u8, c.rand());

    var i: c_int = 0;
    while (i < temp_s1) : (i +%= 1) {
        const section = psx.at(first, i);
        const key = &section.unk2;
        if ((arg2 >= 2 and @as(c_int, psx.getBits(key, "unk0_10")) == arg2) or
            (@as(c_int, psx.getBits(key, "unk0_0")) == arg0 and
                @as(c_int, psx.getBits(key, "unk0_5")) == arg1 and
                @as(c_int, psx.getBits(key, "unk0_10")) == arg2))
        {
            // values[count++]: the index is the count before the increment.
            const index = out.count;
            out.count +%= 1;
            psx.put(psx.at(&out.values, index), section);
        }
    }
    return out;
}
