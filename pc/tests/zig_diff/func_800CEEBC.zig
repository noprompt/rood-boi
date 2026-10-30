//! zig_diff spec: func_800CEEBC -> func_800CEEBC.func_800CEEBC (5BF94.c).
//! Inputs: the four globals the C reads, set by prepare. D_800F531C is drawn
//! around the window 4..5 (with 3, 0 and 0xFFFFFFFF for the unsigned wrap and
//! 6 for the EQUAL case of `< 2`). D_800F5224 and D_800F5228 are signed edges
//! (negatives included, so a signed/unsigned slip shows) and are equal a third
//! of the time. D_800F521C is 0, 1, 2, a value with the sign bit set, or
//! 0xFFFFFFFF, so `> 0` sees zero and nonzero, with and without the sign bit.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CEEBC));

pub const classes = [_][:0]const u8{ "outer-false", "inner-false", "count-zero", "count-nonzero" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const sel: u32 = if (ctx.chance(2))
        ctx.edge(u32, &.{ 3, 4, 5, 6, 0 })
    else
        ctx.pick(u32, &.{ 0xFFFF_FFFF, 0x8000_0000, 7, 2 });
    v.g.D_800F531C().* = sel;

    const edges = [_]i32{ 0, 1, -1, 2147483647, -2147483648, 5 };
    const a = ctx.pick(i32, &edges);
    const b: i32 = if (ctx.chance(3)) a else ctx.pick(i32, &edges);
    v.g.D_800F5224().* = a;
    v.g.D_800F5228().* = b;

    v.g.D_800F521C().* = ctx.pick(u32, &.{ 0, 1, 2, 0x8000_0000, 0xFFFF_FFFF });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const sel = v.g.D_800F531C().*;
    if (sel != 4 and sel != 5) return 0;
    if (v.g.D_800F5224().* <= v.g.D_800F5228().*) return 1;
    return if (v.g.D_800F521C().* == 0) 2 else 3;
}
