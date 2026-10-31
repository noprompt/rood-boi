//! zig_diff spec: func_800CFB68 -> func_800CFB68.func_800CFB68 (5BF94.c).
//! The function is pure arithmetic: no globals, no calls, no branches. The
//! inputs are the three ints themselves, drawn from edge values (0, 1, -1,
//! the i32 extremes, small shifts-around-128 multiples) half the time and
//! any value otherwise. That covers equal endpoints (a1 == a0), negative
//! products (the arithmetic `>> 7` rounds toward minus infinity, unlike
//! `/ 128`), zero and positive products, and products or differences that
//! wrap 32 bits. Classes name those cases so each one is counted.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CFB68));

pub const classes = [_][:0]const u8{ "equal-endpoints", "product-wraps", "product-negative", "product-nonnegative" };

const edges = [_]c_int{
    0,
    1,
    -1,
    2,
    -2,
    127,
    128,
    -128,
    -129,
    255,
    256,
    std.math.maxInt(c_int),
    std.math.minInt(c_int),
    std.math.maxInt(c_int) - 1,
    std.math.minInt(c_int) + 1,
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &edges);
    const arg1 = if (ctx.chance(4)) arg0 else ctx.pick(c_int, &edges);
    const arg2 = ctx.pick(c_int, &edges);
    return .{ arg0, arg1, arg2 };
}

pub fn classify(args: Args) usize {
    const a0: i64 = args[0];
    const a1: i64 = args[1];
    const a2: i64 = args[2];
    if (a0 == a1) return 0;
    const p = (a1 - a0) * a2;
    if (p > std.math.maxInt(i32) or p < std.math.minInt(i32)) return 1;
    return if (p < 0) 2 else 3;
}
