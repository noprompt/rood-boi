//! Steps a sprite position one unit toward its target along the longer axis (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");

/// orig: func_800CFAAC (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Moves the point at unkC/unkE one step toward the point at unk10/unk12 (Bresenham-style, the longer axis always moves).
pub fn func_800CFAAC(arg0: ?*v.func_800CFAAC_t) callconv(.c) void {
    const p = arg0.?;

    // The C compares the two 32-bit words, which is the same as comparing both halves.
    if (p.unkC == p.unk10 and p.unkE == p.unk12) {
        return;
    }

    // All differences are within +-65535 and doubled values within 32 bits, so the plain operators cannot overflow.
    var sx: c_int = -1;
    var sy: c_int = -1;
    var dx: c_int = @as(c_int, p.unk10) - @as(c_int, p.unkC);
    var dy: c_int = @as(c_int, p.unk12) - @as(c_int, p.unkE);
    if (dx < 0) {
        dx = -dx;
        sx = 1;
    }
    if (dy < 0) {
        dy = -dy;
        sy = 1;
    }
    if (dy < dx) {
        p.unk10 = psx.conv(i16, @as(c_int, p.unk10) +% sx);
        if (dx < dy * 2) {
            p.unk12 = psx.conv(i16, @as(c_int, p.unk12) +% sy);
        }
    } else {
        p.unk12 = psx.conv(i16, @as(c_int, p.unk12) +% sy);
        if (dy < dx * 2) {
            p.unk10 = psx.conv(i16, @as(c_int, p.unk10) +% sx);
        }
    }
}
