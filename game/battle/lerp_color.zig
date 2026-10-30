//! Blends two packed RGB colours by a factor and scales the result by brightness
//! (src/BATTLE/BATTLE.PRG/5BF94.c).

/// orig: _lerpColor (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Blends the red, green and blue channels of two colours by blendFactor (0..8), scales by brightness and packs the result.
pub fn lerpColor(color0: c_uint, color1: c_uint, brightness: c_int, blendFactor: c_int) callconv(.c) c_uint {
    // All arithmetic is unsigned 32-bit in C (int operands convert to unsigned), so wrap throughout.
    const bright: c_uint = @bitCast(brightness);
    const f: c_uint = @bitCast(blendFactor);
    const g: c_uint = @as(c_uint, 8) -% f;

    var c0: c_uint = color0;
    var c1: c_uint = color1;
    var ret: c_uint = 0;
    var i: c_uint = 0;
    while (i < 3) : (i +%= 1) {
        const tempLo: c_uint = ((((c0 >> 16) & 0xFF) *% g) +% (((c1 >> 16) & 0xFF) *% f)) *% bright;
        c0 <<= 8;
        ret = (ret << 8) +% (tempLo >> 10);
        c1 <<= 8;
    }

    return ret;
}
