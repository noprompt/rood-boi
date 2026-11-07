//! zig_diff spec: pc_fixed_font_char -> fixed_font_char.fixedFontChar (D2: pc/src/fixed_font.c).
//! Inputs: the cursor word (a guest address in the arena, any alignment), an
//! ordering table of 1024 words with a random slot, the table index
//! (D_800F4E80), font table, colour (D_800F4CB8) and brightness, the glyph
//! widths, the character (a space, or any glyph of the two tables), and
//! 16.16 positions, sizes and scale (edges, negatives, fractions). The two
//! text hooks are recording stubs (the C's null side never runs here); the
//! quad hook's stub also copies the eight corner floats into the arena.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_fixed_font");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").fixedFontChar));

pub const classes = [_][:0]const u8{ "space", "glyph", "second-table", "fractional" };

var kind: usize = 0;
var corners_sink: [*]f32 = undefined;

pub const stubs = struct {
    pub fn pc_ui_precise_quad(ctx: *zd.Ctx, packet: anytype, corners: anytype) void {
        _ = ctx;
        _ = packet;
        for (0..8) |i| corners_sink[i] = corners[i];
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    kind = ctx.range(usize, 0, classes.len - 1);
    const word: *u32 = @ptrCast(@alignCast(ctx.allocBytes(8, 8)));
    const packets = ctx.allocBytes(48, 4);
    corners_sink = @ptrCast(@alignCast(ctx.allocBytes(32, 4)));
    word.* = @intCast(@intFromPtr(packets));
    const table: [*]u32 = @ptrCast(@alignCast(ctx.allocBytes(1024 * 4, 4)));
    for (table[0..1024]) |*slot| slot.* = ctx.int(u32);
    v.g.D_800F51B8().* = @intCast(@intFromPtr(table));
    v.g.D_800F4E80().* = ctx.edge(u8, &.{ 0, 1, 255, ctx.range(u8, 0, 255) });
    v.g._fontTable().* = if (kind == 2) 1 else ctx.range(u8, 0, 1);
    v.g.D_800F4CB8().* = ctx.edge(u8, &.{ 0, 4, 255, ctx.int(u8) });
    v.g._fontBrightness().* = ctx.int(c_uint);
    for (0..380) |i| v.g.vs_battle_characterWidths()[i] = ctx.edge(u8, &.{ 0, 1, 12, 255, ctx.int(u8) });
    const character: c_int = if (kind == 0) 0x8f else ctx.range(c_int, 0, 188);
    const unit: c_uint = 1 << 16;
    const x = ctx.edge(c_uint, &.{ 0, unit, 0xffff8000, 0x7fff0000, 0xffffffff, ctx.int(c_uint) });
    const y = ctx.edge(c_uint, &.{ 0, unit * 224, 0xffff8000, 0x80000000, ctx.int(c_uint) });
    const width = ctx.edge(c_uint, &.{ 0, 12 * unit, 6 * unit, 0xffffffff, ctx.int(c_uint) });
    const height = ctx.edge(c_uint, &.{ 0, 12 * unit, 6 * unit, 0xffff0000, ctx.int(c_uint) });
    const scale = if (kind == 3) ctx.edge(c_uint, &.{ 1 << 15, 3 << 14, ctx.int(c_uint) }) else ctx.edge(c_uint, &.{ 0, unit, 2 * unit, ctx.int(c_uint) });
    return .{ @ptrCast(@alignCast(word)), character, x, y, width, height, scale };
}

pub fn classify(args: Args) usize {
    _ = args;
    return kind;
}
