//! zig_diff spec: vs_battle_lerpVector -> lerp_vector.lerpVector (5BF94.c).
//! Inputs: six shorts in the arena drawn from edges (-32768, -1, 0, 1, 32767
//! and neighbours) or any i16, with start and end equal about a quarter of the
//! time; t an i16 (so (end - start) * t stays inside int and the C has no
//! signed overflow); and a VECTOR in the arena. The C has no null test, so the
//! vector is always valid. Classes split by the sign of t, since that decides
//! the rounding of the arithmetic shift.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").lerpVector));

pub const classes = [_][:0]const u8{ "t-negative", "t-zero", "t-positive" };

const edges = [_]i16{ -32768, -32767, -256, -128, -1, 0, 1, 127, 128, 255, 256, 32766, 32767 };

pub fn prepare(ctx: *zd.Ctx) Args {
    const src: [*c]c_short = @ptrCast(@alignCast(ctx.allocBytes(12, 2)));
    var i: usize = 0;
    while (i < 6) : (i += 1) {
        src[i] = ctx.pick(i16, &edges);
    }
    var k: usize = 0;
    while (k < 3) : (k += 1) {
        if (ctx.chance(4)) src[2 * k + 1] = src[2 * k];
    }
    const t: c_int = ctx.pick(i16, &edges);
    const vec = ctx.alloc(v.VECTOR);
    return .{ src, t, vec };
}

pub fn classify(args: Args) usize {
    const t = args[1];
    if (t < 0) return 0;
    if (t == 0) return 1;
    return 2;
}
