//! zig_diff spec: vs_battle_printVariableWidthFontChar -> print_variable_width_font_char.printVariableWidthFontChar (5BF94.c).
//! Inputs: the space glyph (143, the early return) and font glyphs under
//! _fontTable 0 or 1 (glyph + 189 stays inside the 380-entry width table),
//! x and y around the 16-bit edges (kept clear of C's signed-shift overflow).
//! pc_text_glyph is a linked function, not a writable pointer, so prepare
//! never touches it: the hook is always present. vs_battle_setSprite is a
//! stub that fills its primitive with random words and returns it, so the
//! C's later stores, the trace of its arguments (including nextPrim) and
//! the return value are all compared.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").printVariableWidthFontChar));

pub const classes = [_][:0]const u8{ "space", "glyph" };

pub const stubs = struct {
    pub fn vs_battle_setSprite(ctx: *zd.Ctx, brightnessTransparency: anytype, xy: anytype, wh: anytype, nextPrim: anytype) [*c]c_uint {
        _ = brightnessTransparency;
        _ = xy;
        _ = wh;
        _ = nextPrim;
        const block = ctx.alloc([8]c_uint);
        for (block) |*w| w.* = ctx.value(c_uint);
        return @ptrCast(block);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const font: u8 = ctx.edge(u8, &.{ 0, 1 });
    v.g._fontTable().* = font;

    const glyph: c_uint = blk: {
        if (ctx.chance(5)) break :blk 143;
        if (ctx.chance(4)) break :blk ctx.edge(c_uint, &.{ 0, 20, 21, 41, 42, 142, 144, 189 });
        const limit: c_uint = if (font == 0) 379 else 190;
        break :blk ctx.range(c_uint, 0, limit);
    };

    const x: c_int = if (ctx.chance(2))
        ctx.edge(c_int, &.{ 0, -1, 0x7FFF, -0x8000, 319, -30000, 30000 })
    else
        ctx.range(c_int, -30000, 30000);
    const y: c_int = if (ctx.chance(2))
        ctx.edge(c_int, &.{ 0, 1, -1, 0x7FFF, -0x8000, 240 })
    else
        ctx.range(c_int, -32768, 32767);

    const ot: [*c]c_uint = @ptrCast(ctx.alloc([16]c_uint));
    return .{ glyph, x, y, ot };
}

pub fn classify(args: Args) usize {
    return if (args[0] == 143) 0 else 1;
}
