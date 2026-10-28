//! zig_diff spec: _absMax3 -> abs_max3.absMax3 (5BF94.c).
//! Inputs: three ints drawn three ways: full-range random values, small values
//! in -4..4 whose magnitudes tie often, or edge values (0, +-1, +-2, INT_MAX,
//! INT_MIN), with a set where every argument has the same magnitude. Together
//! they reach each sign test of the three ternaries (negative, zero, positive),
//! both comparisons and the final select, the magnitude ties, and INT_MIN,
//! whose negation wraps back to itself.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").absMax3));

pub const classes = [_][:0]const u8{
    "first-below-second, third above second",
    "first-below-second, third not above second",
    "first-not-below-second, third above first",
    "first-not-below-second, third not above first",
    "tie: first and second magnitudes equal",
    "tie: second and third magnitudes equal",
    "tie: first and third magnitudes equal",
    "an argument is INT_MIN",
};

fn absW(x: i32) i32 {
    return if (x >= 0) x else 0 -% x;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const mode = ctx.range(u8, 0, 3);
    var a: [3]i32 = undefined;
    for (&a) |*x| {
        x.* = switch (mode) {
            0 => ctx.int(i32),
            1 => ctx.range(i32, -4, 4),
            2 => ctx.edge(i32, &.{ 0, 1, -1, 2, -2, std.math.maxInt(i32), std.math.minInt(i32) }),
            else => blk: {
                const m = ctx.range(i32, 0, 3);
                break :blk if (ctx.chance(2)) 0 -% m else m;
            },
        };
    }
    return .{ a[0], a[1], a[2] };
}

pub fn classify(args: Args) usize {
    const min = std.math.minInt(i32);
    if (args[0] == min or args[1] == min or args[2] == min) return 7;
    const t0 = absW(args[0]);
    const a3 = absW(args[1]);
    const v1 = absW(args[2]);
    if (t0 == a3) return 4;
    if (a3 == v1) return 5;
    if (t0 == v1) return 6;
    if (t0 < a3) return if (a3 < v1) 0 else 1;
    return if (t0 < v1) 2 else 3;
}
