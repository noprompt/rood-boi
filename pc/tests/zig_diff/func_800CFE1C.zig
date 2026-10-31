//! zig_diff spec: func_800CFE1C -> func_800CFE1C.func_800CFE1C (5BF94.c).
//! Inputs: a two-short block in the arena whose elements are i16 values drawn
//! from the edges (0, +-1, 127, -128, the i16 extremes) or at random, with the
//! pair equal in a quarter of the runs, and an arg1 that is zero, small,
//! negative, a 128 boundary, or an int extreme whose product with the i16
//! difference wraps. The function has no branches, callees or globals, so the
//! classes split on the sign of the difference (the shift and the signed
//! product are where the port can go wrong).
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CFE1C));

pub const classes = [_][:0]const u8{ "diff-negative", "diff-zero", "diff-positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const block: *[2]c_short = @ptrCast(@alignCast(ctx.allocBytes(4, 2)));
    const edge_vals = [_]c_short{ 0, 1, -1, 127, -128, 32767, -32768 };
    block[0] = ctx.pick(c_short, &edge_vals);
    block[1] = if (ctx.chance(4)) block[0] else ctx.pick(c_short, &edge_vals);
    const arg1: c_int = ctx.pick(c_int, &.{ 0, 1, -1, 127, 128, -128, -129, 0x10000, 0x7FFFFFFF, -0x7FFFFFFF - 1 });
    const p: [*c]c_short = block;
    return .{ p, arg1 };
}

pub fn classify(args: Args) usize {
    const a = args[0];
    const d = @as(i32, a[1]) - @as(i32, a[0]);
    return if (d < 0) 0 else if (d == 0) 1 else 2;
}
