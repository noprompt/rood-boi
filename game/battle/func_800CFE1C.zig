//! Linear interpolation between two shorts in a table (src/BATTLE/BATTLE.PRG/5BF94.c).

/// orig: func_800CFE1C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Interpolates from arg0[0] toward arg0[1] by arg1/128 (arg1 is 0..128).
pub fn func_800CFE1C(arg0: [*c]c_short, arg1: c_int) callconv(.c) c_int {
    const new_var: c_int = arg0[0];
    const diff: c_int = @as(c_int, arg0[1]) -% new_var;
    return ((diff *% arg1) >> 7) +% new_var;
}
