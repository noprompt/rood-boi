//! Fills the slots of D_800F54B8 selected by the bits of arg0 (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D1EF0 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Sets up each slot whose bit is in `mask`, takes its status from func_800D1E78 and marks it in the flags.
pub fn func_800D1EF0(arg0: c_int, arg1: c_int, arg2: c_int, arg3: c_int, arg4: c_int, arg5: c_int, arg6: c_int) callconv(.c) void {
    for (0..4) |i| {
        const bit: u5 = @intCast(i);
        if (((arg0 >> bit) & 1) != 0) {
            const p: *v.D_800F54B8_t = &v.g.D_800F54B8()[i];
            psx.setBits(p, "unk1_0", psx.conv(u5, arg1));
            p.unk4 = psx.conv(u8, arg2);
            psx.setBits(p, "unk1_5", psx.conv(u1, arg3));
            p.unk2 = psx.conv(u8, arg4);
            psx.setBits(p, "unk1_6", psx.conv(u1, arg5));
            p.unk3 = psx.conv(u8, arg6);
            p.unk0 = 0;
            p.unk5 = c.func_800D1E78(@ptrCast(p));
            c.func_800D1DE4(@as(c_int, 1) << bit);
        }
    }
}
