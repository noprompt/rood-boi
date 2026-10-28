//! zig_diff spec: func_8007B344 -> func_8007B344.func_8007B344 (146C.c).
//! Inputs: the two int and three short arguments, each drawn from edge values
//! or any value of its type, so the shorts are negative about half the time
//! and the ints take their extremes. The C only forwards its five arguments to
//! func_800478E0, a void recording stub whose effects the C never reads back,
//! so the call trace (each argument as passed) is the whole check. The C has
//! no branches and no comparisons, so there is nothing else to reach.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B344));

pub const classes = [_][:0]const u8{ "short-negative", "short-nonnegative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{
        ctx.pick(c_int, &.{ 0, -1, 1, 0x7FFF_FFFF, -0x8000_0000 }),
        ctx.pick(c_int, &.{ 0, -1, 0x8000, -0x8001, 0x7FFF_FFFF }),
        ctx.pick(c_short, &.{ 0, -1, 1, 0x7FFF, -0x8000 }),
        ctx.pick(c_short, &.{ 0, -1, 1, 0x7FFF, -0x8000 }),
        ctx.pick(c_short, &.{ 0, -1, 1, 0x7FFF, -0x8000 }),
    };
}

pub fn classify(args: Args) usize {
    return if (args[2] < 0) 0 else 1;
}
