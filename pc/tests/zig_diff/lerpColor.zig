//! zig_diff spec: _lerpColor -> lerp_color.lerpColor (5BF94.c).
//! Inputs: two colors with every channel position populated, including all
//! ones, the bits above each 8-bit channel and the sign bits, so the masks,
//! shifts and wrapping products are exercised. Brightness is 0, 1, -1, the
//! sign-bit extremes or any i32, so the products wrap as unsigned. The
//! blendFactor is in [0, 8] half the time, otherwise past 8 or negative, which
//! makes 8 - blendFactor wrap. The C has no calls, no globals and no ordered
//! comparisons; the port must reproduce its unsigned arithmetic exactly.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").lerpColor));

pub const classes = [_][:0]const u8{ "brightness-zero", "blend-in-range", "blend-past-8", "blend-negative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const color0: c_uint = ctx.pick(c_uint, &.{ 0, 0xFFFF_FFFF, 0x00FF_0000, 0xFF00_FF00, 0x0000_FFFF, 0x8080_8080 });
    const color1: c_uint = ctx.pick(c_uint, &.{ 0, 0xFFFF_FFFF, 0x00FF_0000, 0xFF00_FF00, 0x0000_FFFF, 0x8080_8080 });
    const brightness: c_int = ctx.pick(c_int, &.{ 0, 1, -1, 1024, 0x7FFF_FFFF, -2147483648 });
    const blendFactor: c_int = if (ctx.chance(2))
        ctx.range(c_int, 0, 8)
    else
        ctx.pick(c_int, &.{ -1, 9, 8, 0x7FFF_FFFF, -2147483648 });
    return .{ color0, color1, brightness, blendFactor };
}

pub fn classify(args: Args) usize {
    if (args[2] == 0) return 0;
    if (args[3] < 0) return 3;
    if (args[3] > 8) return 2;
    return 1;
}
