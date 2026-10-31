//! zig_diff spec: func_8007B3D0 -> func_8007B3D0.func_8007B3D0 (146C.c).
//! The C is one call, vs_main_loadClutTransition(arg0, arg1 + 4, arg2, arg3).
//! Inputs: arg0 and arg3 from edge values, arg1 near INT_MAX so that arg1 + 4
//! wraps, and arg2 either null or a 16-byte arena buffer. The callee is
//! declared variadic in the C, so its stub can only take the context: it
//! cannot see or write the buffer. The mutations therefore test the wrapper's
//! own stores and its call, which the buffer compare and the call trace see.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B3D0));

pub const classes = [_][:0]const u8{ "null-buffer", "wrapping-arg1", "plain" };

pub const stubs = struct {
    pub fn vs_main_loadClutTransition(ctx: *zd.Ctx) void {
        _ = ctx;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const a0 = ctx.pick(c_int, &.{ 0, -1, 1, 0x7FFFFFFF, -2147483648 });
    const a1 = ctx.pick(c_int, &.{ 0, -4, -5, 0x7FFFFFFB, 0x7FFFFFFC, 0x7FFFFFFD, 0x7FFFFFFF, -2147483648 });
    const a3 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFFFFFF, -2147483648 });
    var buf: [*c]c_ushort = null;
    if (!ctx.chance(4)) buf = @ptrCast(@alignCast(ctx.allocBytes(16, 2)));
    return .{ a0, a1, buf, a3 };
}

pub fn classify(args: Args) usize {
    if (args[2] == null) return 0;
    if (args[1] >= std.math.maxInt(c_int) - 3) return 1;
    return 2;
}
