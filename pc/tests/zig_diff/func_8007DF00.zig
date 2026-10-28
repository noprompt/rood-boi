//! zig_diff spec: func_8007DF00 -> func_8007DF00.func_8007DF00 (146C.c).
//! The C returns the global D_800F1B9C as an int. It has no branches, so the
//! inputs cover the value edges of that global: zero, one, minus one, the
//! 16-bit boundaries, the 32-bit extremes, and random values, with and without
//! the sign bit. The class is the sign of the value (negative, zero, positive).
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DF00));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F1B9C().* = ctx.pick(i32, &.{
        0,
        1,
        -1,
        0x7FFF,
        -0x8000,
        0x8000,
        0xFFFF,
        std.math.maxInt(i32),
        std.math.minInt(i32),
    });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.D_800F1B9C().*;
    if (x < 0) return 0;
    if (x == 0) return 1;
    return 2;
}
