//! zig_diff spec: func_8008B390 -> func_8008B390.func_8008B390 (146C.c).
//! Inputs: a block count N (-1..7) and N blocks at arg1. Each block's index
//! word is arg1[8+16i] = 4*idx + r (r in 0..3), so `>> 2` gives idx back,
//! and idx is a header of two counts in the arena. Headers sit at positive
//! indices (from 128 ints up, past the block-count and index words) or,
//! for about a quarter of the blocks, at negative indices below arg1 (the
//! arithmetic-shift case). Counts run from -1 to 6 (plus INT_MIN) for both
//! inner loops, so zero, one and several iterations occur and the zones
//! stay inside the arena. arg0 takes the short edges: 0, +-1, the i16
//! limits and wrap points, and the i32 extremes. Zones never share words,
//! so each block's stores land in its own zone.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B390));

pub const classes = [_][:0]const u8{
    "no-blocks",
    "negative-index",
    "both-loops",
    "first-loop-only",
    "second-loop-only",
    "empty-block",
};

const arg1_off: usize = 8192;

const count_edges = [_]c_int{ -1, 0, 0, 1, 2, 3, 4, 6, -2147483648 };

/// The int at `base + 4*k` (k in ints, may be negative).
fn slot(base: usize, k: isize) *c_int {
    return @ptrFromInt(base +% @as(usize, @bitCast(k *% 4)));
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const base: usize = @intFromPtr(&zd.zdiff_arena[arg1_off]);
    const n: c_int = ctx.edge(c_int, &.{ -1, 0, 1, 2, 3, 7 });
    const arg0: c_int = ctx.pick(c_int, &.{
        0, 1, -1, 0x7FFF, -0x8000, 0x8000, 0x10000, 0x7FFFFFFF, -0x7FFFFFFF - 1,
    });
    slot(base, 0).* = n;
    const count: usize = if (n > 0) @intCast(n) else 0;
    for (0..count) |i| {
        const neg = ctx.chance(4);
        const k: isize = ctx.range(isize, 0, 8);
        const bi: isize = @intCast(i);
        const idx: isize = if (neg) -128 * (bi + 1) + k else 128 + 128 * bi + k;
        const r: isize = ctx.range(isize, 0, 3);
        slot(base, @as(isize, @intCast(8 + 16 * i))).* = @intCast(idx * 4 + r);
        slot(base, idx).* = ctx.edge(c_int, &count_edges);
        slot(base, idx + 1).* = ctx.edge(c_int, &count_edges);
    }
    const arg1: [*c]c_int = @ptrCast(@alignCast(&zd.zdiff_arena[arg1_off]));
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    const base: usize = @intFromPtr(args[1]);
    if (slot(base, 0).* <= 0) return 0;
    const idx: isize = slot(base, 8).* >> 2;
    if (idx < 0) return 1;
    const t0 = slot(base, idx).*;
    const t2 = slot(base, idx + 1).*;
    if (t0 > 0 and t2 > 0) return 2;
    if (t0 > 0) return 3;
    if (t2 > 0) return 4;
    return 5;
}
