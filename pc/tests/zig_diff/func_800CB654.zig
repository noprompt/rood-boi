//! zig_diff spec: func_800CB654 -> func_800CB654.func_800CB654 (5BF94.c).
//! Inputs: arg0 across its range: zero and byte-boundary values, -1, the sign
//! bit alone, the 32-bit extremes, plus random values. The C has no branches; its
//! one store, D_800EB9AF = arg0, narrows arg0 to its low byte, so the inputs must
//! differ in bytes above the low one and in the sign bit.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB654));

pub const classes = [_][:0]const u8{ "low-byte-zero", "negative", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const a = ctx.pick(c_int, &.{
        0,          1,         -1,         127,
        128,        255,       256,        -128,
        -256,       0x7FFF_FFFF, -0x7FFF_FFFF - 1, 0x0100_0000,
        0x8000,     0x0000_FF00, 0x0080_0000,
    });
    return .{a};
}

pub fn classify(args: Args) usize {
    const a = args[0];
    if ((a & 0xFF) == 0) return 0;
    if (a < 0) return 1;
    return 2;
}
