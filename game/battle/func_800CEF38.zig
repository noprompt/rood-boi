//! Decrements the counter at D_800F5228 and sets bit `bit` of the flag word at D_800F521C
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: func_800CEF38 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Decrements the counter at D_800F5228 and sets bit `bit` in the flag word at D_800F521C.
pub fn func_800CEF38(bit: c_int) callconv(.c) void {
    v.g.D_800F5228().* -%= 1;
    // The C shifts an int by `bit`; the PS1 and x86 shift by bit & 31, so keep the low 5 bits.
    const bit_u: c_uint = @bitCast(bit);
    v.g.D_800F521C().* |= @as(c_uint, 1) << @as(u5, @truncate(bit_u));
}
