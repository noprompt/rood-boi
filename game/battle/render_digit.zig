//! Digit sprite primitive for the battle number display (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

const Count = *const fn () callconv(.c) c_int;
const Sprite = *const fn (c_int, c_int, c_int, c_int, c_int, c_int, c_int, c_int, c_int, c_int, c_int) callconv(.c) void;
const Place = *const fn (c_int, c_int, [*]u32, [*]u32) callconv(.c) [*]u32;

/// orig: _renderDigit (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// Places one digit sprite of font `font` at `xy`, linked after `before`, with its UV and CLUT words.
pub fn renderDigit(font: c_int, xy: c_int, digit: c_int, before: [*c]c_uint) callconv(.c) void {
    // The shift count is (font * 4) & 31: x86 masks the count to 5 bits.
    const shift: u5 = @truncate(@as(c_uint, @bitCast(font *% 4)));
    const tex: c_int = @bitCast((@as(c_uint, 0x05CA0576) >> shift) & 0xF000F);
    const at: c_int = xy +% ((font & 2) << 16);

    // The sprite the packet was: brightness 128 (colour 0x808080, not semi-transparent), the default texture page (draw mode
    // 0x0C), texels (32, 11) and the digit's CLUT; for a digit its texel word is overwritten by the digit's place in the font.
    var uv: c_int = 32 | (11 << 8);
    if (font != 2) uv = (((digit *% 2) +% 64) *% (font +% 3)) -% 192;

    // As an item placed where the packet linked (draw_items.h).
    const sprite = psx.weak(Sprite, "pc_frame_sprite").?;
    const count = psx.weak(Count, "pc_frame_count").?;
    const place = psx.weak(Place, "pc_frame_place").?;
    const first = count();
    sprite(0, @as(i16, @truncate(at)), @as(i16, @truncate(at >> 16)), tex & 0xFFFF, tex >> 16, uv & 0xFF, (uv >> 8) & 0xFF, 0x808080,
        (223 << 6) | ((832 >> 4) & 0x3f), 0x0C, 0);
    const scratch = v.g.vs_scratch();
    const cursor: [*]u32 = @ptrCast(@alignCast(psx.get(scratch.unk0).?));
    psx.put(&scratch.unk0, @as(*anyopaque, @ptrCast(place(first, count() - first, @ptrCast(@alignCast(before)), cursor))));
}
