//! zig_diff spec: func_8007C4AC -> func_8007C4AC.func_8007C4AC (146C.c).
//! Inputs: three random c_int arguments, each drawn from the edges 0, 1, -1,
//! 7, INT_MAX and INT_MIN half the time and any value otherwise. The C has no
//! branches and no calls: it stores the constant 7 into the transition step
//! and the three arguments into the effect, speed and wipe-angle globals. The
//! globals start as random bytes and are compared after the run, so every
//! store must match in both runs.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C4AC));

pub const classes = [_][:0]const u8{ "effect-negative", "effect-nonnegative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const edges = [_]c_int{ 0, 1, -1, 7, std.math.maxInt(c_int), std.math.minInt(c_int) };
    return .{
        ctx.pick(c_int, &edges),
        ctx.pick(c_int, &edges),
        ctx.pick(c_int, &edges),
    };
}

pub fn classify(args: Args) usize {
    return if (args[0] < 0) 0 else 1;
}
