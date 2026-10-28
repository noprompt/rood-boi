//! zig_diff spec: func_8007BEC4 -> func_8007BEC4.func_8007BEC4 (146C.c).
//! Inputs: the one int argument, drawn from the edges (0, 1, -1, INT_MIN,
//! INT_MAX) half the time and any 32-bit value otherwise, so the high and
//! low halves are both set. The C only forwards arg0 to func_800CEF74 and
//! returns nothing, so the port must make the same call with the same
//! argument. The callee's int result is discarded and its stub returns a
//! fresh value each call; its only possible writes are to globals and the
//! scratchpad, which the harness already randomises and compares.
const std = @import("std");
const zd = @import("zdiff");
const port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_8007BEC4));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub const stubs = struct {
    /// The callee's result is discarded by the C; return a value anyway so
    /// the stub is not a constant. Any state the callee changes is randomised
    /// by the harness and compared through the call trace.
    pub fn func_800CEF74(ctx: *zd.Ctx, arg: anytype) c_int {
        _ = arg;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.pick(c_int, &.{ 0, 1, -1, std.math.minInt(c_int), std.math.maxInt(c_int) });
    return .{arg};
}

pub fn classify(args: Args) usize {
    const arg = args[0];
    if (arg == 0) return 0;
    if (arg < 0) return 1;
    return 2;
}
