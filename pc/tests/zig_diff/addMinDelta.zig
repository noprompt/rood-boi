//! zig_diff spec: _addMinDelta -> add_min_delta.addMinDelta (146C.c).
//! Inputs: a random base (within +-2^29) and two operands a and b, each an
//! edge value (0, +-1, +-2, +-7, +-2^30) or a random value within +-2^30, with
//! b == a a quarter of the time so the ordered comparisons see equal sides.
//! The bounds keep the C's signed additions free of overflow (undefined in
//! C). Every branch is reached: b < 0 with a >= b and a nonzero, b < 0 with
//! a >= b and a zero, b < 0 with a < b, b >= 0 with b >= a and a nonzero, and
//! the final else (b < a or a zero).
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").addMinDelta));

pub const classes = [_][:0]const u8{
    "neg-b-a-ge-b-a-nonzero",
    "neg-b-a-ge-b-a-zero",
    "neg-b-a-lt-b",
    "nonneg-b-ge-a-a-nonzero",
    "else",
};

const big: c_int = 1 << 30;
const edges = [_]c_int{ 0, 1, -1, 2, -2, 7, -7, big, -big };

fn operand(ctx: *zd.Ctx) c_int {
    if (ctx.chance(2)) return ctx.edge(c_int, &edges);
    return ctx.range(c_int, -big, big);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const base = ctx.range(c_int, -(1 << 29), 1 << 29);
    const a = operand(ctx);
    const b = if (ctx.chance(4)) a else operand(ctx);
    return .{ base, a, b };
}

pub fn classify(args: Args) usize {
    const a = args[1];
    const b = args[2];
    if (b < 0) {
        if (a >= b) {
            return if (a != 0) 0 else 1;
        }
        return 2;
    }
    if (b >= a and a != 0) return 3;
    return 4;
}
