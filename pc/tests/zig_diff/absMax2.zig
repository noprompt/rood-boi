//! zig_diff spec: _absMax2 -> abs_max2.absMax2 (5BF94.c).
//! Inputs: two c_ints drawn from edge values (0, +-1, +-2, +-100, the int
//! extremes, and INT_MIN, where the negation wraps), with arg1 sometimes set
//! to -arg0 or arg0 so the magnitudes tie often. Classes: arg0 is INT_MIN,
//! the magnitudes tie, arg1 is the larger magnitude, arg0 is the larger.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").absMax2));

pub const classes = [_][:0]const u8{ "int-min-arg0", "tie", "arg1-larger", "arg0-larger" };

const edges = [_]c_int{ 0, 1, -1, 2, -2, 100, -100, 0x7FFF_FFFF, -0x7FFF_FFFF, -2147483648 };

pub fn prepare(ctx: *zd.Ctx) Args {
    const a0 = ctx.pick(c_int, &edges);
    var a1 = ctx.pick(c_int, &edges);
    switch (ctx.range(u8, 0, 3)) {
        0 => a1 = 0 -% a0, // equal magnitude, opposite sign
        1 => a1 = a0, // equal values
        else => {},
    }
    return .{ a0, a1 };
}

pub fn classify(args: Args) usize {
    const x: i64 = args[0];
    const y: i64 = args[1];
    if (x == -2147483648) return 0;
    const ax = if (x < 0) -x else x;
    const ay = if (y < 0) -y else y;
    if (ax == ay) return 1;
    if (ay > ax) return 2;
    return 3;
}
