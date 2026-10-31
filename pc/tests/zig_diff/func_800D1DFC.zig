//! zig_diff spec: func_800D1DFC -> func_800D1DFC.func_800D1DFC (5BF94.c).
//! Inputs: the int argument at zero, negative (sign bit set), and positive,
//! with the edges 1, 0x80, 0xFF, 0x100, INT_MIN and INT_MAX mixed in. The
//! global D_800F5518 starts as random bytes, so the masked clear is checked
//! against every prior value; the zero branch stores 0 over those bytes.
const std = @import("std");
const zd = @import("zdiff");
const port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_800D1DFC));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.pick(c_int, &.{
        0,
        1,
        -1,
        0x80,
        0xFF,
        0x100,
        std.math.minInt(c_int),
        std.math.maxInt(c_int),
    })};
}

pub fn classify(args: Args) usize {
    const a = args[0];
    if (a == 0) return 0;
    return if (a < 0) 1 else 2;
}
