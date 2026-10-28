//! zig_diff spec: func_8008C518 -> func_8008C518.func_8008C518 (146C.c).
//! The C body is one call, func_8008C49C(arg0, -1), whose int result is
//! discarded. Inputs: arg0 drawn from the sign boundaries and zero, plus
//! random values, classed negative, zero and positive. The callee is a
//! recording stub that writes no state and returns a value the C ignores,
//! so the observable behaviour is the call's arguments and its order.
const std = @import("std");
const zd = @import("zdiff");
const port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_8008C518));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub const stubs = struct {
    /// The callee's int result is discarded by the C; it writes no state here.
    pub fn func_8008C49C(ctx: *zd.Ctx, a: anytype, b: anytype) c_int {
        _ = a;
        _ = b;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.pick(c_int, &.{ 0, -1, 1, 2, std.math.maxInt(c_int), std.math.minInt(c_int) })};
}

pub fn classify(args: Args) usize {
    const x = args[0];
    if (x < 0) return 0;
    if (x == 0) return 1;
    return 2;
}
