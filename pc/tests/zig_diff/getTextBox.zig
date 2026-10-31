//! zig_diff spec: vs_battle_getTextBox -> get_text_box.getTextBox (5BF94.c).
//! Inputs: an id in the table (0-7), just past it (8 and up, including
//! 0x7fffffff), negative (-1, -8, INT_MIN), or any random c_int. The C
//! only computes the element address and never dereferences it, so every
//! index is safe; the returned pointers are compared as addresses. The C
//! has no branches or value tests, so the classes split by where the index
//! falls relative to the 8-entry table.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getTextBox));

pub const classes = [_][:0]const u8{ "in-table", "past-table", "negative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const id: c_int = switch (ctx.range(u8, 0, 3)) {
        0 => ctx.range(c_int, 0, 7),
        1 => ctx.edge(c_int, &.{ 8, 9, 100, 0x7fff_ffff }),
        2 => ctx.edge(c_int, &.{ -1, -8, -9, std.math.minInt(c_int) }),
        else => ctx.int(c_int),
    };
    return .{id};
}

pub fn classify(args: Args) usize {
    const id = args[0];
    if (id < 0) return 2;
    if (id < 8) return 0;
    return 1;
}
