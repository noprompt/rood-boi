//! zig_diff spec: func_8007BE10 -> func_8007BE10.func_8007BE10 (146C.c).
//! Inputs: the argument arg0 as any c_int, half the time one of the edges
//! 0, -1, 1, INT_MAX and INT_MIN, otherwise a random value. The C stores it
//! into D_800F18B0 and returns the stored value, so every run checks the
//! global's final bytes and the return value. The function has no branches
//! and no calls, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_8007BE10));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.pick(c_int, &.{ 0, -1, 1, std.math.maxInt(c_int), std.math.minInt(c_int) })};
}

pub fn classify(args: Args) usize {
    const x = args[0];
    if (x < 0) return 0;
    if (x == 0) return 1;
    return 2;
}
