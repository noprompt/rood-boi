//! zig_diff spec: vs_battle_renderValue -> render_value.renderValue (5BF94.c).
//! Inputs: `before` is null (the C takes it from vs_scratch.unk4 minus 16 words,
//! so unk4 points 64 bytes into an arena block) or an arena array. The value,
//! font and xy are any c_int from edges and random bits, so xy - 5 - font can
//! wrap. vs_battle_toBCD shrinks its argument by 16 on each call, so the digit
//! loop always ends, and it sometimes negates the result, so the loop sees
//! negative and positive values. _renderDigit writes into *before, as the
//! real digit drawer does.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").renderValue));

pub const classes = [_][:0]const u8{ "before-null", "given-negative", "given-one-digit", "given-several-digits" };

pub const stubs = struct {
    pub fn vs_battle_toBCD(ctx: *zd.Ctx, value: c_int) c_int {
        const shrunk = @divTrunc(value, 16);
        return if (ctx.value(u1) == 1) -shrunk else shrunk;
    }

    pub fn _renderDigit(ctx: *zd.Ctx, font: anytype, xy: anytype, digit: anytype, before: anytype) void {
        _ = font;
        _ = xy;
        _ = digit;
        if (before != null) before[0] = ctx.value(c_uint);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const scratch = v.g.vs_scratch();
    const block = ctx.allocBytes(512, 16);
    const target: *anyopaque = @ptrCast(block + 64);
    psx.put(&scratch.unk4, target);

    const before: [*c]c_uint = if (ctx.chance(3)) null else @ptrCast(ctx.alloc([8]c_uint));
    const value = ctx.pick(c_int, &.{ 0, 1, -1, 15, 16, -16, -17, std.math.maxInt(c_int), std.math.minInt(c_int) });
    const xy = ctx.pick(c_int, &.{ 0, 5, -5, std.math.maxInt(c_int), std.math.minInt(c_int) });
    const font = ctx.pick(c_int, &.{ 0, 1, -1, 8, std.math.maxInt(c_int), std.math.minInt(c_int) });
    return .{ font, xy, value, before };
}

pub fn classify(args: Args) usize {
    if (args[3] == null) return 0;
    if (args[2] < 0) return 1;
    return if (args[2] < 16) 2 else 3;
}
