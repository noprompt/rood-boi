//! zig_diff spec: func_8007DFF0 -> func_8007DFF0.func_8007DFF0 (146C.c).
//! Inputs: arg0 low (0..24, including the 24 edge), in range (25..32, with
//! 24 and 32 as edges), or past the table with arg0 >= 33 (up to 0x7FFFFFFF,
//! and the high-bit unsigned values). arg1 is drawn so that arg0 + arg1 stays
//! below, at and above 33 without wrapping: a wrapped sum would run the loops
//! over the 32-entry table out of range, which the C itself would fault on.
//! At arg0 == 24 arg1 stays small, so a mutant that enters the span branch
//! there returns or calls differently instead of walking off the table.
//! Inside the span the table is either cleared (the store loop runs) or has
//! one entry set to 1, 0x80 or 0xFF (the busy path). arg2 is any int, so
//! its low byte is what gets stored.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DFF0));

pub const classes = [_][:0]const u8{ "arg0-low", "span-past-33", "span-busy", "span-clear" };

/// Prepares the table span [arg0, arg0 + arg1) for the in-range path:
/// either all zero (the store loop runs) or one nonzero entry.
fn prepareSpan(ctx: *zd.Ctx, table: [*]u8, arg0: c_uint, arg1: c_uint) void {
    if (arg1 == 0) return;
    if (ctx.chance(2)) {
        var i: c_uint = 0;
        while (i < arg1) : (i += 1) table[arg0 + i] = 0;
    } else {
        table[arg0 + ctx.range(c_uint, 0, arg1 - 1)] = ctx.edge(u8, &.{ 1, 0x80, 0xFF });
    }
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.D_800F19A8();
    var arg0: c_uint = 0;
    var arg1: c_uint = 0;
    switch (ctx.range(u8, 0, 3)) {
        0 => {
            // arg0 <= 24: the C skips the span entirely. At 24 keep arg1 small
            // so no sum wraps; elsewhere the wrapping edge is harmless.
            arg0 = if (ctx.chance(2)) ctx.edge(c_uint, &.{ 0, 23, 24 }) else ctx.range(c_uint, 0, 24);
            if (arg0 == 24) {
                arg1 = ctx.edge(c_uint, &.{ 0, 1, 8 });
            } else {
                arg1 = ctx.pick(c_uint, &.{ 0, 1, 8, 0xFFFF_FFFF });
            }
        },
        1 => {
            // arg0 in 25..32; arg1 up to 40 - arg0 so the sum crosses 33 (33 itself is common).
            arg0 = if (ctx.chance(3)) ctx.edge(c_uint, &.{ 24, 25, 32 }) else ctx.range(c_uint, 25, 32);
            arg1 = ctx.range(c_uint, 0, 40 - arg0);
            if (arg0 > 0x18 and arg0 + arg1 < 0x21) prepareSpan(ctx, table, arg0, arg1);
        },
        2 => {
            // arg0 + arg1 >= 33 with no wrap: the span is not touched.
            arg0 = if (ctx.chance(3)) 33 else ctx.range(c_uint, 33, 0x7FFF_FFFF);
            arg1 = if (ctx.chance(3)) 0 else ctx.range(c_uint, 0, 0x7FFF_FFFF);
        },
        else => {
            // arg0 with the high bit set (unsigned compare); arg1 = 0 so the sum is arg0.
            arg0 = ctx.range(c_uint, 0x8000_0000, 0xFFFF_FFFF);
            arg1 = 0;
        },
    }
    return .{ arg0, arg1, ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    const arg1 = args[1];
    if (arg0 <= 0x18) return 0;
    if (@as(u64, arg0) + arg1 >= 0x21) return 1;
    const table = v.g.D_800F19A8();
    var i: c_uint = 0;
    while (i < arg1) : (i += 1) {
        if (table[arg0 + i] != 0) return 2;
    }
    return 3;
}
