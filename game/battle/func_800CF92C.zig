//! Packs two clamped screen-space bytes into one 16-bit value (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;

/// orig: func_800CF92C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Stores into `arg3` the x byte (low 8 bits, from the low half of arg2 plus arg0) and the y byte (from arg2's high half plus arg1), each clamped to 1..254.
pub fn func_800CF92C(arg0: c_int, arg1: c_int, arg2: c_int, arg3: [*c]c_short) callconv(.c) void {
    var var_v1: c_int = @as(c_int, psx.conv(i16, arg2)) +% arg0;

    if (var_v1 <= 0) {
        var_v1 = 1;
    } else if (var_v1 >= 0xFF) {
        var_v1 = 0xFE;
    }

    var temp_a1: c_int = (arg2 >> 16) +% arg1;

    if (temp_a1 <= 0) {
        temp_a1 = 1;
    } else if (temp_a1 >= 0xFF) {
        temp_a1 = 0xFE;
    }

    // Both bytes are in 1..254 here, so the shift and OR stay within 16 bits.
    arg3.* = psx.conv(c_short, var_v1 | (temp_a1 << 8));
}
