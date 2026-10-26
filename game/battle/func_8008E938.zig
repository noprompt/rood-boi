//! Room section B setup: resets the room's origin and scale, then fixes up the
//! room's bounds from its collision map (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008E938 (src/BATTLE/BATTLE.PRG/146C.c)
/// Resets the room origin and scale, and sizes the bounds of the room's section B.
pub fn func_8008E938() callconv(.c) void {
    v.g.D_800F1DB4().* = 0;
    v.g.D_800F1DB6().* = 0;
    v.g.D_800F1DB8().* = 0x1000;
    v.g.D_800F1DBA().* = 0x1000;

    if (psx.get(v.g.vs_battle_roomData().sectionB)) |temp| {
        var i: c_int = 1;
        while (i < 5) : (i +%= 1) {
            if (temp.unk0[0] != temp.unk0[@intCast(i)]) {
                break;
            }
        }
        if (i == 5 and (temp.unk0[0] & 0xFFFFFF) != 0) {
            v.g.D_800F1DC6().* = 1;
        } else {
            v.g.D_800F1DC6().* = 0;
            c.func_8008EB30(@ptrCast(&temp.unk0));
        }

        if (temp.unk48[0].s32 == 0 and temp.unk48[1].s32 == 0) {
            if (psx.get(v.g.vs_battle_roomData().collisionMapSection)) |collisionMap| {
                temp.unk48[1].s16[0] = psx.conv(i16, @as(c_int, collisionMap.width) *% 4);
                temp.unk48[1].s16[1] = psx.conv(i16, @as(c_int, collisionMap.height) *% 4);
            } else {
                temp.unk48[1].s16[0] = 0x20;
                temp.unk48[1].s16[1] = 0x20;
            }
        }

        temp.unk48[0].s16[0] = psx.conv(i16, @as(c_int, temp.unk48[0].s16[0]) *% 128);
        temp.unk48[0].s16[1] = psx.conv(i16, @as(c_int, temp.unk48[0].s16[1]) *% 128);
        temp.unk48[1].s16[0] = psx.conv(i16, @as(c_int, temp.unk48[1].s16[0]) *% 128);
        temp.unk48[1].s16[1] = psx.conv(i16, @as(c_int, temp.unk48[1].s16[1]) *% 128);
        temp.unk48[1].s16[0] = psx.conv(i16, @as(c_int, temp.unk48[1].s16[0]) -% @as(c_int, temp.unk48[0].s16[0]));
        temp.unk48[1].s16[1] = psx.conv(i16, @as(c_int, temp.unk48[1].s16[1]) -% @as(c_int, temp.unk48[0].s16[1]));
    }
}
