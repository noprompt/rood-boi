//! Dispatches a battle record by its code (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D0C60 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Codes below 0x10 fill the record from two helpers; 0x10 and 0x11 run func_800D0984, 0x12 runs func_800D0B08.
pub fn func_800D0C60(arg0: c_int, arg1: ?*v.func_800D0C60_t) callconv(.c) void {
    const rec = arg1.?;
    if (rec.unk34 < 0x10) {
        var sp20: [2]c_int = undefined;
        c.func_800A1720(@as(c_int, rec.unk34), @as(c_int, rec.unk35), psx.cptr(c.func_800CFE98_t, &rec.unk78), &sp20);
        var sp10: v.func_8006EBF8_t = undefined;
        _ = c.func_800A1108(@as(c_int, rec.unk34), &sp10);
        rec.unkBE = sp10.unk0.unk4.pad;
        return;
    }
    switch (rec.unk34) {
        0x10, 0x11 => c.func_800D0984(arg0, psx.cptr(c.func_800D0C60_t, rec), @as(c_int, @intFromBool(rec.unk34 != 0x10))),
        0x12 => c.func_800D0B08(psx.cptr(c.func_800CFE98_t, &rec.unk78)),
        else => {},
    }
}
