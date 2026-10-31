//! zig_diff spec: func_800D1E20 -> func_800D1E20.func_800D1E20 (5BF94.c).
//! Inputs: the argument at its edges (0, +-1, 0x7FFF, 0x8000, 0xFFFF, 0x10000,
//! the 32-bit extremes) and random values. The unit reads no object and makes no
//! call; it stores the argument into the global D_800F55E8, whose prior contents
//! (random, set in prepare) the port must overwrite. Every bit of the argument
//! reaches the store, so narrowing or sign slips are visible.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D1E20));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    // A random prior value of the global, so a port that skips the store is caught.
    v.g.D_800F55E8().* = ctx.int(u32);
    return .{ctx.pick(c_int, &.{ 0, -1, 1, 0x7FFF, 0x8000, 0xFFFF, 0x10000, std.math.maxInt(c_int), std.math.minInt(c_int) })};
}

pub fn classify(args: Args) usize {
    const x = args[0];
    if (x == 0) return 0;
    return if (x < 0) 1 else 2;
}
