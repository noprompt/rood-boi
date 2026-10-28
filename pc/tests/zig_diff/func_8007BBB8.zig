//! zig_diff spec: func_8007BBB8 -> func_8007BBB8.func_8007BBB8 (146C.c).
//! The C body is one call, func_80069DEC(arg0, arg1), with no branches and no
//! comparisons of its own. The inputs are the two int arguments, drawn from
//! edge values (0, 1, -1, 2, INT_MAX, INT_MIN) and random ints, so the
//! recorded call arguments cover signs, zero and the extremes. The callee is
//! a void recording stub: it returns nothing and the C reads back no global,
//! out-parameter or scratchpad byte after it, so the default stub models it.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BBB8));

pub const classes = [_][:0]const u8{ "both-zero", "some-negative", "both-positive", "zero-and-positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const edges = [_]c_int{ 0, 1, -1, 2, std.math.maxInt(c_int), std.math.minInt(c_int) };
    return .{ ctx.pick(c_int, &edges), ctx.pick(c_int, &edges) };
}

pub fn classify(args: Args) usize {
    const a = args[0];
    const b = args[1];
    if (a == 0 and b == 0) return 0;
    if (a < 0 or b < 0) return 1;
    if (a > 0 and b > 0) return 2;
    return 3;
}
