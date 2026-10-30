//! zig_diff spec: func_800CD3A0 -> func_800CD3A0.func_800CD3A0 (5BF94.c).
//! Inputs: two random-edge c_ints. arg1's flag bits (0 and 1) take all four
//! combinations, with and without the sign bit, and arg0 covers the byte
//! boundaries, the sign bit and the wrap at the extremes. The function makes
//! no calls and reads no globals, so nothing else is built.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CD3A0));

pub const classes = [_][:0]const u8{ "flags-none", "flags-bit0", "flags-bit1", "flags-both" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 0xFF, 0xFF00, 0x7FFF_FFFF, -0x8000_0000, 0x8000, 0x1234_5678 });
    const arg1 = ctx.pick(c_int, &.{ 0, 1, 2, 3, -1, -2, -3, -0x8000_0000, 0x7FFF_FFFE, 0x100 });
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    return @intCast(args[1] & 3);
}
