//! zig_diff spec: func_8007D15C -> func_8007D15C.func_8007D15C (146C.c).
//! Inputs: an arbitrary c_int `arg0`, drawn from the sign and extreme edges
//! (0, 1, -1, 15, 16, INT_MAX, INT_MIN) and random values. The C takes no
//! pointers and reads no globals of its own, so the only state it touches is
//! what `func_8007D08C` does: the stub records the call and returns an
//! arbitrary value, which the C ignores. The loop always runs i = 1..15, so
//! every run reaches both the loop body and the exit (`i == 16`).
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007D15C));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub const stubs = struct {
    /// The callee's return value is never read by the C; its state effects
    /// are covered by the state comparison at each call.
    pub fn func_8007D08C(ctx: *zd.Ctx, a: anytype, b: anytype) c_int {
        _ = a;
        _ = b;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = if (ctx.chance(2))
        ctx.pick(c_int, &.{ 0, 1, -1, 15, 16, std.math.maxInt(c_int), std.math.minInt(c_int) })
    else
        ctx.int(c_int);
    return .{arg};
}

pub fn classify(args: Args) usize {
    const a = args[0];
    if (a < 0) return 0;
    if (a == 0) return 1;
    return 2;
}
