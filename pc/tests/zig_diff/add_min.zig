//! zig_diff spec: _add_min -> add_min.add_min (146C.c).
//! The inputs are a base and two addends drawn from edge values (0, +-1, +-2,
//! the 8- and 16-bit extremes, the i32 extremes) or any random int. A quarter
//! of the runs set b = a, so both ordered tests on a and b see equal sides, and
//! an eighth set b = 0, so `b < 0` sees equal sides too. Classes follow the
//! branches: b negative with a below or not below b; b nonnegative with b below
//! a, a equal to b, or a below b. Overflow is covered by the extreme edges: the
//! C's `base += x` wraps, so the port uses wrapping adds. There are no callees
//! and no globals.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").add_min));

pub const classes = [_][:0]const u8{
    "b-negative-a-below-b",
    "b-negative-a-not-below-b",
    "b-nonnegative-below-a",
    "a-equals-b",
    "a-below-b-nonnegative",
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const edges = [_]c_int{ 0, 1, -1, 2, -2, 127, -128, 32767, -32768, 2147483647, -2147483648 };
    const base = ctx.pick(c_int, &edges);
    const a = ctx.pick(c_int, &edges);
    var b = ctx.pick(c_int, &edges);
    if (ctx.chance(4)) b = a; // a == b: the `a < b` and `b < a` tests see equal sides
    if (ctx.chance(8)) b = 0; // `b < 0` sees equal sides
    return .{ base, a, b };
}

pub fn classify(args: Args) usize {
    const a = args[1];
    const b = args[2];
    if (b < 0) return if (a < b) 0 else 1;
    if (b < a) return 2;
    if (a == b) return 3;
    return 4;
}
