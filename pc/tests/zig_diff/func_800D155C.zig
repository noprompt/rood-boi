//! zig_diff spec: func_800D155C -> func_800D155C.func_800D155C (5BF94.c).
//! Inputs: the five int arguments are random full-range values, biased
//! toward 0, -1, INT_MIN and INT_MAX, so the products wrap. arg4 is biased
//! toward the ONE-step edges (0, 4096, 8192, -4096, -8192, 4095, 4097, 1)
//! and the extremes. arg5 is a fresh arena int with a random value. The C
//! has no calls, globals or branches, so the spec only needs the arguments.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D155C));

pub const classes = [_][:0]const u8{ "arg4-edge", "arg4-negative", "arg4-large", "arg4-small" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const out = ctx.alloc(c_int);
    out.* = ctx.int(c_int);
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, std.math.maxInt(c_int), std.math.minInt(c_int) });
    const arg1 = ctx.pick(c_int, &.{ 0, 1, -1, std.math.maxInt(c_int), std.math.minInt(c_int) });
    const arg2 = ctx.pick(c_int, &.{ 0, 1, -1, std.math.maxInt(c_int), std.math.minInt(c_int) });
    const arg3 = ctx.pick(c_int, &.{ 0, 1, -1, std.math.maxInt(c_int), std.math.minInt(c_int) });
    const arg4 = ctx.pick(c_int, &.{ 0, 4096, 8192, -4096, -8192, 4095, 4097, 1, std.math.maxInt(c_int), std.math.minInt(c_int) });
    return .{ arg0, arg1, arg2, arg3, arg4, out };
}

pub fn classify(args: Args) usize {
    const a4 = args[4];
    if (a4 == 0 or a4 == 4096 or a4 == 8192) return 0;
    if (a4 < 0) return 1;
    if (a4 > 65536) return 2;
    return 3;
}
