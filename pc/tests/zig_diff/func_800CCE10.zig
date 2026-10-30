//! zig_diff spec: func_800CCE10 -> func_800CCE10.func_800CCE10 (5BF94.c).
//! Inputs: an index arg0 over the table's 9 entries, arg1 with every
//! ((arg1 >> 2) & 3) selector (so both `||` operands and both the flip and
//! no-flip paths run), arg2 and arg3 across the 12-bit and 32-bit wrap edges,
//! and table entries whose 12-bit offsets sit at the signed edges (-2048 is
//! the one whose negation wraps). The class is the selector.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CCE10));

pub const classes = [_][:0]const u8{ "sel0", "sel1", "sel2", "sel3" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.D_800EC284();
    const a0 = ctx.range(c_int, 0, 8);
    const a1 = ctx.pick(c_int, &.{ 0, 4, 8, 12, -1, std.math.minInt(c_int), std.math.maxInt(c_int) });
    const a2 = ctx.pick(c_int, &.{
        0,                        -1,                  1,
        0x2AAA_AAAA,              0x2AAA_AAAB,         -0x2AAA_AAAA,
        std.math.maxInt(c_int),   std.math.minInt(c_int),
    });
    const a3 = ctx.pick(c_int, &.{
        0,                        -1,                  1,
        0x0EC4_EC4F,              0x0EC4_EC4E,         -0x0EC4_EC4F,
        std.math.maxInt(c_int),   std.math.minInt(c_int),
    });
    if (ctx.chance(2)) {
        const e = &table[@intCast(a0)][ctx.range(usize, 0, 1)];
        psx.setBits(e, "unk0_0", ctx.pick(i12, &.{ -2048, 2047, -1, 0 }));
        psx.setBits(e, "unk0_12", ctx.pick(i12, &.{ -2048, 2047, -1, 0 }));
        psx.setBits(e, "unk0_24", ctx.int(u2));
    }
    return .{ a0, a1, a2, a3 };
}

pub fn classify(args: Args) usize {
    const sel: u32 = (@as(u32, @bitCast(args[1])) >> 2) & 3;
    return @intCast(sel);
}
