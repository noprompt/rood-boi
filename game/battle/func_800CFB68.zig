//! Linear interpolation step between two values in 1/128 units (src/BATTLE/BATTLE.PRG/5BF94.c).

/// orig: func_800CFB68 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns arg0 moved toward arg1 by arg2/128 of the distance, rounding toward negative infinity.
pub fn func_800CFB68(arg0: c_int, arg1: c_int, arg2: c_int) callconv(.c) c_int {
    return ((arg1 -% arg0) *% arg2 >> 7) +% arg0;
}
