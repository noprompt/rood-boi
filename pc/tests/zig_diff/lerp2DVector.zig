//! zig_diff spec: vs_battle_lerp2DVector -> lerp2_dvector.lerp2DVector (5BF94.c).
//! Inputs: a src quad of shorts (extremes, zero, -1, equal start and end
//! sometimes), a random t drawn from edges (0, +-1, 127/128, 16-bit and 32-bit
//! extremes), and a vec pair in the arena. The C has no branches, so the
//! classes split by t: zero, negative, positive without overflow, and products
//! (end - start) * t that overflow an int, where the result wraps.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
const c = @import("c_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").lerp2DVector));

pub const classes = [_][:0]const u8{ "t-zero", "t-negative", "t-positive", "t-product-overflows" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const src = ctx.alloc([4]c_short);
    const vec = ctx.alloc([2]c_int);
    for (src) |*s| {
        s.* = ctx.pick(c_short, &.{ -32768, 32767, -1, 0, 1, -128, 127 });
    }
    if (ctx.chance(4)) src[1] = src[0];
    if (ctx.chance(4)) src[3] = src[2];
    const t = ctx.pick(c_int, &.{ 0, 1, -1, 127, 128, -128, 32767, -32768, 0x7fffffff, -0x80000000 });
    const s: [*c]c_short = @ptrCast(src);
    const out: [*c]c_int = @ptrCast(vec);
    return .{ s, t, out };
}

pub fn classify(args: Args) usize {
    const src = args[0];
    const t = args[1];
    if (t == 0) return 0;
    if (t < 0) return 1;
    const d0 = @as(i64, src[1]) - @as(i64, src[0]);
    const d1 = @as(i64, src[3]) - @as(i64, src[2]);
    const p0 = d0 * @as(i64, t);
    const p1 = d1 * @as(i64, t);
    const lo = @as(i64, std.math.minInt(c_int));
    const hi = @as(i64, std.math.maxInt(c_int));
    if (p0 < lo or p0 > hi or p1 < lo or p1 > hi) return 3;
    return 2;
}
