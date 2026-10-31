//! BCD packing helper for battle display values (src/BATTLE/BATTLE.PRG/5BF94.c).
/// orig: vs_battle_toBCD (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Packs a value's last two decimal digits into BCD: units in the low nibble, tens in the high.
pub fn toBCD(value: c_int) callconv(.c) c_int {
    // C's % and / truncate toward zero; the tens product wraps as -fwrapv does.
    return @rem(value, 10) | (@divTrunc(value, 10) *% 16);
}
