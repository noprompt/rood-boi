//! zig_diff spec: func_8007980C -> func_8007980C.func_8007980C (146C.c).
//! Inputs: the global D_800F1868 is set to edge values around its low two
//! bits and its sign bit (0, 1..3, 4, 8, -1..-4, the i32 extremes, 0x40000000,
//! 0x7FFFFFFC), half of them picked from that list and half random. The
//! C's one test, `!(D & 3)`, then takes both sides, with and without the sign
//! bit. The callee func_8006FA20 is void and returns nothing the C reads back,
//! so its recording stub needs no behaviour.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007980C));

pub const classes = [_][:0]const u8{
    "low-bits-zero-nonneg",
    "low-bits-zero-neg",
    "low-bits-set-nonneg",
    "low-bits-set-neg",
};

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F1868().* = ctx.pick(i32, &.{
        0,      1,  2,          3,          4,          8,
        -1,     -2, -3,         -4,         std.math.minInt(i32),
        std.math.maxInt(i32), 0x40000000, 0x7FFFFFFC,
    });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F1868().*;
    const low_zero = (d & 3) == 0;
    const neg = d < 0;
    const base: usize = if (low_zero) 0 else 2;
    return base + (if (neg) @as(usize, 1) else 0);
}
