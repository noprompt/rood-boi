//! zig_diff spec: vs_battle_decreaseMiscCount -> decrease_misc_count.decreaseMiscCount (5BF94.c).
//! Inputs: a miscId from edges around 0x143 (0x142, 0x143, 0x144), negative values,
//! the int extremes, or a random int; a misc inventory whose ids are often drawn
//! from the same edges and often hold a planted match of the low 16 bits of miscId
//! (0xFFFF included, so a signed id compare would diverge); counts 0, 1, 2 and 255
//! (0 wraps the decremented int to -1, which must not clear the id); and a
//! miscItemInvoked start from edges so the search wraps past slot 63. The C
//! reads and writes only globals: no pointers and no callees, so no stubs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").decreaseMiscCount));

pub const classes = [_][:0]const u8{
    "not-found",
    "found-first-probe",
    "found-later-probe",
    "count-to-zero",
    "count-was-zero",
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const miscId: c_int = ctx.pick(c_int, &.{ 0, 1, 0x142, 0x143, 0x144, -1, 0x7FFF_FFFF, -0x8000_0000 });
    const low: u16 = @truncate(@as(u32, @bitCast(miscId)));
    const inv = v.g.vs_main_inventory();
    for (&inv.misc) |*m| {
        m.id = ctx.pick(u16, &.{ 0, 1, 0x142, 0x143, 0x144, 0xFFFF });
        m.count = ctx.pick(u8, &.{ 0, 1, 2, 255 });
    }
    if (ctx.chance(3)) inv.misc[ctx.range(usize, 0, 63)].id = low;
    v.g.vs_battle_miscItemInvoked().* = ctx.pick(u8, &.{ 0, 1, 31, 32, 63, 64, 255 });
    return .{miscId};
}

pub fn classify(args: Args) usize {
    const miscId = args[0];
    const inv = v.g.vs_main_inventory();
    var start: usize = v.g.vs_battle_miscItemInvoked().*;
    if (miscId < 0x143) start = 0;
    var i: usize = 0;
    while (i < 64) : (i += 1) {
        const idx = (start + i) & 0x3F;
        const m = inv.misc[idx];
        if (@as(c_int, m.id) == miscId) {
            if (m.count == 0) return 4;
            if (m.count == 1) return 3;
            return if (i == 0) 1 else 2;
        }
    }
    return 0;
}
