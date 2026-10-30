//! Digit sprite primitive for the battle number display (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const c = @import("c_5BF94");

/// orig: _renderDigit (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Places one digit sprite of font `font` at `xy`, linked after `before`, with its UV and CLUT words.
pub fn renderDigit(font: c_int, xy: c_int, digit: c_int, before: [*c]c_uint) callconv(.c) void {
    // The shift count is (font * 4) & 31: x86 masks the count to 5 bits.
    const shift: u5 = @truncate(@as(c_uint, @bitCast(font *% 4)));
    const tex: c_int = @bitCast((@as(c_uint, 0x05CA0576) >> shift) & 0xF000F);
    const prim = c.vs_battle_setSpriteDefaultTexPage(
        128,
        xy +% ((font & 2) << 16),
        tex,
        before,
    );

    prim[4] = (32 | (11 << 8)) | (((223 << 6) | ((832 >> 4) & 0x3f)) << 16);

    if (font != 2) {
        // Halfword 8 of the primitive: byte offset 16, the low half of prim[4].
        const shorts: [*]align(1) i16 = @ptrCast(prim);
        shorts[8] = psx.conv(i16, (((digit *% 2) +% 64) *% (font +% 3)) -% 192);
    }
}
