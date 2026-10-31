//! zig_diff spec: func_800CEF38 -> func_800CEF38.func_800CEF38 (5BF94.c).
//! Inputs: arg0 in 0..31 (a shift by 32 or more, or a negative one, is
//! undefined in C, so it is never built), the counter D_800F5228 at its
//! edges and at random (never INT_MIN, whose decrement is undefined in C),
//! and the bit mask D_800F521C random, so bits are sometimes already set.
//! Classes split arg0 into the low and high halves of the 32-bit mask.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CEF38));

pub const classes = [_][:0]const u8{ "shift-low", "shift-high" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const counter = v.g.D_800F5228();
    counter.* = if (ctx.chance(2))
        ctx.edge(i32, &.{ 0, 1, -1, 2147483647, -2147483647, -2 })
    else
        ctx.range(i32, -2147483647, 2147483647);
    v.g.D_800F521C().* = ctx.int(u32);
    return .{ctx.range(c_int, 0, 31)};
}

pub fn classify(args: Args) usize {
    return if (args[0] < 16) 0 else 1;
}
