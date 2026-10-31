//! zig_diff spec: func_8008E7BC -> func_8008E7BC.func_8008E7BC (146C.c).
//! Inputs: one row of D_800E849C (arg2 0..6, so arg2+1 stays inside its 8
//! entries) with an empty range (equal bounds, or an end below zero), a
//! reversed range with a non-negative end, and a short range of 1-4 rows.
//! The fixed table D_800E84AC is rewritten each run as char rows of 4 with
//! small values (0, 1, 2, 3, 0xFF, 0x80), so the argument pairs match table
//! rows often: a match at the start row, at the end row, or in the middle,
//! through either clause. Matching rows return unk186[i], whose bit 7 is
//! random, so a signed-char read differs. Stubs: none, the C makes no calls.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E7BC));

pub const classes = [_][:0]const u8{ "equal-bounds", "end-negative", "reversed", "range" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const tab = v.g.D_800E849C();
    const arg2: c_uint = ctx.range(c_uint, 0, 6);
    var start: i16 = ctx.range(i16, 0, 5);
    const mode = ctx.range(u8, 0, 3);
    var end: i16 = undefined;
    switch (mode) {
        0 => end = start,
        1 => end = ctx.range(i16, -32768, -1),
        2 => {
            if (start == 0) start = 1;
            end = start - 1;
        },
        else => end = start + ctx.range(i16, 1, 4),
    }
    tab[arg2] = start;
    tab[arg2 + 1] = end;

    // The fixed table D_800E84AC: char rows of 4 (get_D_800E84AC(i, 0..3)),
    // rows 0..9 used here. Small values, some negative, so pairs collide.
    const bytes = psx.globalMany(u8, "D_800E84AC");
    for (0..40) |k| bytes[k] = ctx.edge(u8, &.{ 0, 1, 2, 3, 0xFF, 0x80 });

    var arg0: c_int = ctx.edge(c_int, &.{ -1, 0, 1, 2, 3, 127, -128, 255 });
    var arg1: c_int = ctx.edge(c_int, &.{ -1, 0, 1, 2, 3, 127, -128, 255 });
    if (end > start and !ctx.chance(4)) {
        const row: i16 = switch (ctx.range(u8, 0, 3)) {
            0 => start,
            1 => end,
            else => start + ctx.range(i16, 0, end - start),
        };
        const base: usize = @as(usize, @intCast(row)) * 4;
        const col: usize = if (ctx.chance(2)) 0 else 2;
        arg0 = @as(i8, @bitCast(bytes[base + col]));
        arg1 = @as(i8, @bitCast(bytes[base + col + 1]));
    }
    return .{ arg0, arg1, arg2 };
}

pub fn classify(args: Args) usize {
    const tab = v.g.D_800E849C();
    const start = tab[args[2]];
    const end = tab[args[2] + 1];
    if (start == end) return 0;
    if (end < 0) return 1;
    if (end < start) return 2;
    return 3;
}
