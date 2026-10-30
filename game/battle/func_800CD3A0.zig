//! Battle unit 5BF94: inverts the low and/or high byte of a 16-bit value (src/BATTLE/BATTLE.PRG/5BF94.c).

/// orig: func_800CD3A0 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Bit 0 of `flags` inverts the high byte of `value`; bit 1 inverts its low byte.
pub fn func_800CD3A0(arg0: c_int, arg1: c_int) callconv(.c) c_int {
    var var_v1: c_int = arg0;

    if ((arg1 & 1) != 0) {
        // The shift left may discard bits (C's << on negative int is two's complement).
        var_v1 = (var_v1 & 0xFF) | @as(c_int, @bitCast(@as(c_uint, @bitCast(0xFF -% (var_v1 >> 8))) << 8));
    }

    if ((arg1 & 2) != 0) {
        var_v1 = (~var_v1 & 0xFF) | (var_v1 & 0xFF00);
    }

    return var_v1;
}
