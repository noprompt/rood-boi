//! Clears one bit in the i32 flag array at D_800F5320 (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: func_800CF514 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Clears flag bit `arg0` in the word array D_800F5320 (the word index rounds toward zero for negative bits).
pub fn func_800CF514(arg0: c_int) callconv(.c) void {
    const ptr = v.g.D_800F5320();
    var var_v1: c_int = arg0;
    if (arg0 < 0) {
        var_v1 = arg0 +% 0x1F;
    }
    var_v1 >>= 5;
    // The shift amount can be negative for arg0 in -31..-1 (UB in C); x86 masks it to its low 5 bits, so truncate.
    const shift: u5 = @truncate(@as(c_uint, @bitCast(arg0 -% (var_v1 << 5))));
    const bit: c_int = @bitCast(@as(c_uint, 1) << shift);
    psx.at(ptr, var_v1).* &= ~bit;
}
