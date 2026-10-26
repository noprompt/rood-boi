//! zig_diff spec: vs_battle_initTextBox -> init_text_box.initTextBox (5BF94.c).
//! Inputs: a box index 0-7 of vs_battle_textBoxes over random bytes; flags whose
//! low nibble selects the switch (1, 4, 5, or no case) with random high bits, so
//! the 0xFFFF mask is exercised; state at 0 (the `<=` equality) a third of the
//! time and otherwise negative, positive or extreme; coordinates from edge values
//! and ranges that keep x + 5, y + 3 and h * 13 clear of int overflow; and any
//! int for charsPerLine, centerX and centerY, which are stored narrowed.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").initTextBox));

pub const classes = [_][:0]const u8{ "case-1", "case-4", "case-5", "no-case" };

/// A coordinate: edge values half the time, otherwise a range where x + 5 cannot overflow.
fn coord(ctx: *zd.Ctx) c_int {
    if (ctx.chance(2)) return ctx.edge(c_int, &.{ 0, -1, 1, 5, -5, 32767, -32768, 32768, 65535, -65536, 0x3FFF_FFFF, -0x4000_0000 });
    return ctx.range(c_int, -0x4000_0000, 0x4000_0000);
}

/// A line count: small and negative values, otherwise a range where h * 13 cannot overflow.
fn lines(ctx: *zd.Ctx) c_int {
    if (ctx.chance(2)) return ctx.edge(c_int, &.{ 0, 1, -1, 2, -2, 255, 256, -256 });
    return ctx.range(c_int, -0x0400_0000, 0x0400_0000);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const id: c_int = ctx.range(c_int, 0, 7);
    const nib = ctx.edge(c_int, &.{ 1, 4, 5, 0, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 });
    const flags: c_int = (ctx.int(c_int) & ~@as(c_int, 0xF)) | nib;
    const box = &v.g.textBoxes()[@intCast(id)];
    box.state = if (ctx.chance(3)) 0 else ctx.pick(i16, &.{ -1, 1, 32767, -32768 });
    const x = coord(ctx);
    const y = coord(ctx);
    const charsPerLine = ctx.int(c_int);
    const h = lines(ctx);
    const centerX = ctx.int(c_int);
    const centerY = ctx.int(c_int);
    return .{ id, flags, x, y, charsPerLine, h, centerX, centerY };
}

pub fn classify(args: Args) usize {
    return switch (args[1] & 0xF) {
        1 => 0,
        4 => 1,
        5 => 2,
        else => 3,
    };
}
