//! zig_diff spec: vs_battle_toBCD -> to_bcd.toBCD (5BF94.c).
//! Inputs: a c_int drawn from edge values (0, +-1, +-9, +-10, 99, 100, 16,
//! 255, INT_MIN, INT_MAX) half the time and any c_int otherwise. Negative
//! values exercise the signed `%` and `/` and the OR of negative remainders;
//! the function has no branches, calls or globals, so the classes only
//! separate the negative, zero and positive halves of the input range.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").toBCD));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const value = ctx.pick(c_int, &.{ 0, 1, 9, 10, -1, -9, -10, 16, 99, 100, 255, 0x7FFF_FFFF, -0x7FFF_FFFF - 1 });
    return .{value};
}

pub fn classify(args: Args) usize {
    const value = args[0];
    if (value < 0) return 0;
    if (value == 0) return 1;
    return 2;
}
