//! zig_diff spec: func_800D18B4 -> func_800D18B4.func_800D18B4 (5BF94.c).
//! Inputs: any c_int endpoints (0, 1, -1, 4096, INT_MAX, INT_MIN, random), a
//! nonzero divisor arg2 (random, or edges such as 1, -1, 2, 4096, INT_MAX),
//! and arg3 kept within +/-2^19 (edges 0, +/-1, 2, 0x7FFFF, -0x80000 and random
//! values in between) so arg3 * 4096 / 2 never overflows and the divisor
//! never meets INT_MIN / -1. The C has no branches of its own: rcos and
//! vs_battle_lerp are recording stubs whose default int return is
//! ctx.value(c_int), so each one returns an arbitrary value in both runs.
//! Classes split the inputs by the signs of arg2 and arg3, which decide the
//! sign of the quotient fed to rcos.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D18B4));

pub const classes = [_][:0]const u8{
    "arg2-pos-arg3-pos",
    "arg2-pos-arg3-neg",
    "arg2-neg-arg3-pos",
    "arg2-neg-arg3-neg",
};

const endpoint_edges = [_]c_int{ 0, 1, -1, 4096, std.math.maxInt(c_int), std.math.minInt(c_int) };
const divisor_edges = [_]c_int{ 1, -1, 2, -2, 3, -3, 4096, -4096, 0x7FFF_FFFF, -0x7FFF_FFFF };
const arg3_edges = [_]c_int{ 0, 1, -1, 2, -2, 0x7FFFF, -0x80000 };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &endpoint_edges);
    const arg1 = ctx.pick(c_int, &endpoint_edges);

    var arg2 = ctx.pick(c_int, &divisor_edges);
    if (arg2 == 0) arg2 = 1;

    const arg3: c_int = if (ctx.chance(2))
        ctx.edge(c_int, &arg3_edges)
    else
        ctx.range(c_int, -(1 << 19), 1 << 19);

    return .{ arg0, arg1, arg2, arg3 };
}

pub fn classify(args: Args) usize {
    const arg2_index: usize = if (args[2] < 0) 2 else 0;
    const arg3_index: usize = if (args[3] < 0) 1 else 0;
    return switch (arg2_index + arg3_index) {
        0 => 0,
        1 => 1,
        2 => 2,
        else => 3,
    };
}
