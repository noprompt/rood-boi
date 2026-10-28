//! zig_diff spec: func_8007CC6C -> func_8007CC6C.func_8007CC6C (146C.c).
//! The C is a single forwarding call, `func_8009CE9C(arg0)`, with no branches
//! and no global or object reads. The inputs cover the edges of the argument:
//! 0, 1, -1, INT_MIN, INT_MAX, and random values, split into negative and
//! non-negative classes so both sides of the sign bit reach the call. The
//! callee's return value is discarded by the C and uses the default int stub,
//! which returns a deterministic `ctx.value(c_int)`; the call trace compares the
//! argument each run passes.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CC6C));

pub const classes = [_][:0]const u8{ "negative", "nonnegative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.pick(c_int, &.{ 0, 1, -1, std.math.maxInt(c_int), std.math.minInt(c_int) })};
}

pub fn classify(args: Args) usize {
    return if (args[0] < 0) 0 else 1;
}
