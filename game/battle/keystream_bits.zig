//! Advances the battle keystream and returns its previous state shifted by `32 - value` (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: vs_battle_keystreamBits (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Steps the keystream state by the LCG multiplier and returns the old state shifted right by `32 - value`.
pub fn keystreamBits(value: c_int) callconv(.c) c_uint {
    const old: c_uint = v.g._keystreamState().*;
    v.g._keystreamState().* = old *% 0x19660D;
    // The shift count is 32 - value taken mod 32, as the x86 shift instruction masks it.
    const amount: u5 = @truncate(@as(c_uint, 32) -% @as(c_uint, @bitCast(value)));
    return old >> amount;
}
