//! Requests a battle effect through func_800CF0E8 and resets the tick speed (src/BATTLE/BATTLE.PRG/146C.c).
const std = @import("std");
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_800733F8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Starts effect `effectId` with a zeroed request, then sets the tick speed and calls func_800CB654(1) and func_8008B4C8(0).
pub fn func_800733F8(arg0: c_int) callconv(.c) void {
    // ROOD_PC: the request is zeroed first, since func_800CF3F8 copies all of it.
    var sp10 = std.mem.zeroes(v.func_800CF0E8_t);

    sp10.effectId = psx.conv(u16, arg0);
    v.g.D_800F196C().* = 4;
    sp10.unk2 = 1;
    sp10.unk3 = 0;
    sp10.unk4 = 4;
    sp10.unk8.u8[0] = 0;
    sp10.unk8.u8[1] = 0;
    sp10.unkA.u8[0] = 0;
    sp10.unk10 = 4;
    sp10.unk14.u8[0] = 0;
    sp10.unk14.u8[1] = 0;
    sp10.unk16.u8[0] = 0;
    sp10.unkE0.vz = 0;
    sp10.unkE0.vy = 0;
    sp10.unkE0.vx = 0;
    _ = c.func_800CF0E8(psx.cptr(c.func_800CF0E8_t, &sp10), 0, 0);
    v.g.vs_gametime_tickspeed().* = 4;
    c.func_800CB654(1);
    _ = c.func_8008B4C8(0);
}
