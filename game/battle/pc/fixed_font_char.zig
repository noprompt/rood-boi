//! Fixed-width glyph packets (D2: 5BF94.c's assembly; oracle pc/src/fixed_font.c).
const c = @import("c_fixed_font");
const v = @import("views_fixed_font");
const psx = @import("common").psx;

const PreciseQuad = *const fn (?*const anyopaque, [*c]const f32) callconv(.c) void;
const TextGlyph = *const fn (?*const ?*anyopaque, c_int, c_int, c_int, c_int, c_int, c_int) callconv(.c) void;

/// orig: pc_fixed_font_char (pc/src/fixed_font.c)
/// Emits the textured quad of `character` (the current font table) at x, y,
/// width by height (all 16.16), into the packet at the guest word `cursor`,
/// links it into the ordering table, moves the cursor on and returns the next
/// x (the glyph's width times `scale`; a space is 6 times it). The text
/// hooks, when linked, see the quad's unrounded corners and the glyph.
pub fn fixedFontChar(cursor: [*c][*c]c_uint, character: c_int, x: c_uint, y: c_uint, width: c_uint, height: c_uint, scale: c_uint) callconv(.c) c_int {
    // The cursor, the table and the packets are guest addresses the C uses as-is (any alignment).
    @setRuntimeSafety(false);
    if (character == 0x8f) {
        if (psx.weak(TextGlyph, "pc_text_glyph")) |glyph_hook| {
            glyph_hook(null, 0, -1, @bitCast(x), @bitCast(y), @bitCast(x +% scale *% 6), 6);
        }
        return @bitCast(x +% scale *% 6);
    }
    const glyph: c_uint = @bitCast(character +% @as(c_int, v.g._fontTable().*) *% 189);
    const word: *u32 = @ptrCast(cursor);
    const packet: [*]c_uint = @ptrFromInt(@as(usize, word.*));
    const table: [*]c_uint = @ptrFromInt(@as(usize, v.g.D_800F51B8().*));
    const head: *c_uint = &table[@as(usize, v.g.D_800F4E80().*) *% 4 +% 3];
    const clut: c_uint = (((@as(c_uint, v.g.D_800F4CB8().*) *% 16 +% 0x340) >> 4) & 63) | 0x3780;
    const row = glyph / 21;
    const column = glyph % 21;
    const left = column *% 12;
    const right = left +% 12;
    const top = (row *% 12) << 8;
    const bottom = top +% 0xc00;
    packet[0] = 0x09000000 | (head.* & 0xffffff);
    packet[1] = v.g._fontBrightness().*;
    packet[2] = (x >> 16) | (y & 0xffff0000);
    packet[3] = left | top | (clut << 16);
    packet[4] = ((x +% width) >> 16) | (y & 0xffff0000);
    packet[5] = right | top | 0x000d0000;
    packet[6] = (x >> 16) | ((y +% height) & 0xffff0000);
    packet[7] = left | bottom;
    packet[8] = ((x +% width) >> 16) | ((y +% height) & 0xffff0000);
    packet[9] = right | bottom;
    if (psx.weak(PreciseQuad, "pc_ui_precise_quad")) |quad_hook| {
        // The unrounded corners (16.16), for sub-pixel text.
        const x0: f32 = @as(f32, @floatFromInt(@as(c_int, @bitCast(x)))) / 65536.0;
        const y0: f32 = @as(f32, @floatFromInt(@as(c_int, @bitCast(y)))) / 65536.0;
        const x1: f32 = @as(f32, @floatFromInt(@as(c_int, @bitCast(x +% width)))) / 65536.0;
        const y1: f32 = @as(f32, @floatFromInt(@as(c_int, @bitCast(y +% height)))) / 65536.0;
        const corners = [8]f32{ x0, y0, x1, y0, x0, y1, x1, y1 };
        quad_hook(packet + 1, &corners); // the command, as the GPU walker sees it
    }
    const advance: c_uint = v.g.vs_battle_characterWidths()[glyph];
    if (psx.weak(TextGlyph, "pc_text_glyph")) |glyph_hook| {
        var command: ?*anyopaque = packet + 1;
        glyph_hook(&command, 1, @bitCast(glyph), @bitCast(x), @bitCast(y), @bitCast(x +% advance *% scale), @bitCast(advance));
    }
    head.* = psx.addr(packet) & 0xffffff;
    word.* = psx.addr(packet + 10);
    return @bitCast(x +% advance *% scale);
}

/// orig: _printFixedWidthFontChar (pc/src/fixed_font.c)
/// One glyph at x, y into the packets at the scratchpad's cursor (word 0).
pub fn printFixedWidthFontChar(character: c_int, x: c_int, y: c_int, width: c_int, height: c_int, scale: c_int) callconv(.c) c_int {
    return c.pc_fixed_font_char(@ptrFromInt(0x1f800000), character, @bitCast(x), @bitCast(y), @bitCast(width), @bitCast(height), @bitCast(scale));
}
