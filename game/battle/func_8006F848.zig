//! Sends battle effect 20 to func_800CF3F8 with a zeroed request (src/BATTLE/BATTLE.PRG/146C.c).
const std = @import("std");
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8006F848 (src/BATTLE/BATTLE.PRG/146C.c)
/// Requests effect 20 from func_800CF3F8 with the fields the C sets; the rest of the request is zero.
pub fn func_8006F848() callconv(.c) void {
    var sp10: v.func_800CF0E8_t = std.mem.zeroes(v.func_800CF0E8_t);

    sp10.effectId = 20;
    sp10.unk2 = 1;
    sp10.unk4 = 5;
    sp10.unk10 = 4;
    sp10.unk3 = 0;
    sp10.unk14.u8[0] = 0;
    sp10.unk16.u8[0] = 0xFD;
    _ = c.func_800CF3F8(psx.cptr(c.func_800CF0E8_t, &sp10), 0);
}
