//! zig_diff spec: func_800CF92C -> func_800CF92C.func_800CF92C (5BF94.c).
//! Inputs: arg2 is built from an edge-biased low half (the (short) part) and an
//! edge-biased high half (the `>> 16` part), so both sums hit the clamp edges
//! 0 and 255 exactly, sit just outside them, or fall between them. arg0 and
//! arg1 are chosen so that (short)arg2 + arg0 and (arg2 >> 16) + arg1 equal a
//! chosen target; sometimes they are wholly random within +-70000 instead.
//! arg3 is an arena short prefilled with random bytes, so the stored value
//! must overwrite it completely.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF92C));

pub const classes = [_][:0]const u8{
    "x_low_y_low",   "x_low_y_high",   "x_low_y_mid",
    "x_high_y_low",  "x_high_y_high",  "x_high_y_mid",
    "x_mid_y_low",   "x_mid_y_high",   "x_mid_y_mid",
};

const half_edges = [_]i16{ 0, 1, -1, 2, 127, -128, 254, 255, 256, -255, 32767, -32768 };
const target_edges = [_]i32{ 0, 1, -1, 2, 128, 254, 255, 256, 300 };

pub fn prepare(ctx: *zd.Ctx) Args {
    const out = ctx.alloc(c_short);
    const lo = ctx.pick(i16, &half_edges);
    const hi = ctx.pick(i16, &half_edges);
    // (short)arg2 == lo and arg2 >> 16 == hi.
    const arg2: i32 = @as(i32, hi) * 65536 + @as(i32, @as(u16, @bitCast(lo)));

    const arg0: i32 = if (ctx.chance(4))
        ctx.range(i32, -70000, 70000)
    else
        ctx.edge(i32, &target_edges) - @as(i32, lo);

    const arg1: i32 = if (ctx.chance(4))
        ctx.range(i32, -70000, 70000)
    else
        ctx.edge(i32, &target_edges) - @as(i32, hi);

    return .{ arg0, arg1, arg2, out };
}

pub fn classify(args: Args) usize {
    const x = @as(i32, @as(i16, @truncate(args[2]))) + args[0];
    const y = (args[2] >> 16) + args[1];
    const xc: usize = if (x <= 0) 0 else if (x >= 255) 1 else 2;
    const yc: usize = if (y <= 0) 0 else if (y >= 255) 1 else 2;
    return xc * 3 + yc;
}
