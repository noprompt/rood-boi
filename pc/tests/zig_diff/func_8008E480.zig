//! zig_diff spec: func_8008E480 -> func_8008E480.func_8008E480 (146C.c).
//! Inputs: the one argument, an int, over its edges (0, 1, -1, INT_MAX,
//! INT_MIN) and random values. The C only forwards arg0 to two void callees
//! and reads nothing back, so there is no branch, no global and no return
//! value to model. The callees keep the harness's recording stubs: the
//! checker compares the call order, each call's argument and the state
//! hash at each call.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E480));

pub const classes = [_][:0]const u8{"any"};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, std.math.maxInt(c_int), std.math.minInt(c_int) });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
