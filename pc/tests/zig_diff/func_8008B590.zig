//! zig_diff spec: func_8008B590 -> func_8008B590.func_8008B590 (146C.c).
//! Inputs: a MATRIX in the arena, filled with random bytes so that the
//! translation and any field the C does not write show up as differences,
//! and an int angle drawn from the edges 0, -1, 1, 4095, 4096, INT_MIN and
//! INT_MAX or any value. rsin and rcos return i16-range values, including
//! both extremes, so every product stays inside the C's int arithmetic and
//! the divisions see negative operands.

const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B590));

pub const classes = [_][:0]const u8{ "angle-zero", "angle-negative", "angle-wide", "angle-small" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const m = ctx.alloc(v.MATRIX);
    const angle = ctx.pick(c_int, &.{ 0, -1, 1, 4095, 4096, std.math.minInt(c_int), std.math.maxInt(c_int) });
    return .{ m, angle };
}

pub fn classify(args: Args) usize {
    const angle = args[1];
    if (angle == 0) return 0;
    if (angle < 0) return 1;
    if (angle >= 4096) return 2;
    return 3;
}

/// A sine or cosine result: the extremes of i16 sometimes, any i16 otherwise.
fn sample(ctx: *zd.Ctx) c_int {
    return switch (ctx.value(u2)) {
        0 => -32768,
        1 => 32767,
        else => @as(c_int, ctx.value(i16)),
    };
}

pub const stubs = struct {
    pub fn rsin(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        return sample(ctx);
    }
    pub fn rcos(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        return sample(ctx);
    }
};
