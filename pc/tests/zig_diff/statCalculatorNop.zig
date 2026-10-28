//! zig_diff spec: _statCalculatorNop -> stat_calculator_nop.statCalculatorNop (146C.c).
//! The C body is empty, so there are no branches and no calls. The inputs are
//! three valid objects in the arena (every pointer argument non-null, so a
//! port that stores through one is caught by the state compare) and integer
//! arguments drawn from edges (0, -1, 1, the int extremes) and random values.
//! Classes split on the sign of arg3, which the signed-test mutation needs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").statCalculatorNop));

pub const classes = [_][:0]const u8{ "arg3-negative", "arg3-non-negative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const a0 = ctx.alloc(v.vs_action_t);
    const a1 = ctx.alloc(v._hitEntity_t);
    const a2 = ctx.alloc(v._hitEntity_t);
    const arg3 = ctx.pick(c_int, &.{ 0, -1, 1, std.math.minInt(c_int), std.math.maxInt(c_int) });
    const arg4 = ctx.pick(c_int, &.{ 0, -1, 1, std.math.minInt(c_int), std.math.maxInt(c_int) });
    return .{ a0, a1, a2, arg3, arg4 };
}

pub fn classify(args: Args) usize {
    return if (args[3] < 0) 0 else 1;
}
