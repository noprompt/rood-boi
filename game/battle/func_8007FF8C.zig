//! Scales a value by a factor that is 105% when any of the first three entries at 0x30-byte strides from 0xCA has byte value 9, else 100% (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;

/// orig: func_8007FF8C (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns arg1 scaled by 100, or by 105 when a byte at 0xCA + 0x30*i (i < 3) equals 9.
pub fn func_8007FF8C(_: c_int, arg1: c_short, arg2: [*c]u8) callconv(.c) c_short {
    var var_t0: c_int = 100;
    var var_a3: c_int = 0;
    var i: c_int = 0;

    while (i < 3) : (i +%= 1) {
        if (psx.at(arg2, i *% 0x30 +% 0xCA).* == 9) {
            var_a3 = 1;
        }
    }

    if (var_a3 != 0) {
        var_t0 +%= 5;
    }
    return psx.conv(c_short, @divTrunc(@as(c_int, arg1) *% var_t0, 100));
}
