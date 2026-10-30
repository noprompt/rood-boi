//! zig_diff spec: func_800CFAAC -> func_800CFAAC.func_800CFAAC (5BF94.c).
//! Inputs: one func_800CFAAC_t in the arena with random bytes in its unk0 and
//! its four i16 coordinates drawn from a small range around zero, so the
//! ordered tests (dx < 0, dy < dx, dx < dy * 2, dy < dx * 2) see equal sides
//! often, plus full-range i16 values for large differences. The same-point
//! early return, the x-only-equal and y-only-equal cases, and both signs of
//! each difference are all generated. The C never tests its argument for
//! null, so the object is always present.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CFAAC));

pub const classes = [_][:0]const u8{
    "same-point",
    "x-major, y steps too",
    "x-major, x only",
    "y-major, x steps too",
    "y-major, y only",
};

const small = [_]i16{ -3, -2, -1, 0, 1, 2, 3, 4, 5, 6 };

pub fn prepare(ctx: *zd.Ctx) Args {
    const o = ctx.alloc(v.func_800CFAAC_t);

    o.unkC = if (ctx.chance(6)) ctx.pick(i16, &.{ 32767, -32768 }) else ctx.edge(i16, &small);
    o.unkE = if (ctx.chance(6)) ctx.pick(i16, &.{ 32767, -32768 }) else ctx.edge(i16, &small);

    if (ctx.chance(10)) {
        // Full-range targets: large differences, both signs.
        o.unk10 = ctx.int(i16);
        o.unk12 = ctx.int(i16);
    } else {
        o.unk10 = o.unkC +% ctx.edge(i16, &small);
        o.unk12 = o.unkE +% ctx.edge(i16, &small);
    }

    if (ctx.chance(8)) {
        // Same point: the early return.
        o.unk10 = o.unkC;
        o.unk12 = o.unkE;
    } else if (ctx.chance(8)) {
        // Same x only: dx == 0, the y axis moves.
        o.unk10 = o.unkC;
    } else if (ctx.chance(8)) {
        // Same y only: dy == 0, the x axis moves.
        o.unk12 = o.unkE;
    }

    return .{o};
}

pub fn classify(args: Args) usize {
    const o = args[0].?;
    if (o.unkC == o.unk10 and o.unkE == o.unk12) return 0;
    const dx: i32 = @as(i32, o.unk10) - @as(i32, o.unkC);
    const dy: i32 = @as(i32, o.unk12) - @as(i32, o.unkE);
    const ax: i32 = if (dx < 0) -dx else dx;
    const ay: i32 = if (dy < 0) -dy else dy;
    if (ay < ax) return if (ax < ay * 2) 1 else 2;
    return if (ay < ax * 2) 3 else 4;
}
