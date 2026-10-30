//! zig_diff spec: func_8008EAE4 -> func_8008EAE4.func_8008EAE4 (146C.c).
//! Inputs: two random c_int arguments, drawn from edge values (0, -1, the i16
//! limits, one past each i16 limit, the c_int limits) half the time and from
//! any c_int otherwise. The C stores each argument into an i16 global, so the
//! wrapping cases (arg outside the i16 range) are the ones that show a porter
//! narrowing or swapping the stores wrongly. The C has no branches and no
//! calls; the globals start as random bytes and are compared after the run.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008EAE4));

pub const classes = [_][:0]const u8{ "both-fit-i16", "arg0-wraps-i16", "arg1-wraps-i16" };

const edges = [_]c_int{
    0,
    -1,
    1,
    32767,
    -32768,
    32768,
    -32769,
    65535,
    65536,
    std.math.maxInt(c_int),
    std.math.minInt(c_int),
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const a = ctx.pick(c_int, &edges);
    const b = ctx.pick(c_int, &edges);
    return .{ a, b };
}

fn fitsI16(x: c_int) bool {
    return x >= std.math.minInt(i16) and x <= std.math.maxInt(i16);
}

pub fn classify(args: Args) usize {
    if (!fitsI16(args[0])) return 1;
    if (!fitsI16(args[1])) return 2;
    return 0;
}
