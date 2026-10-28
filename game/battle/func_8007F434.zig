//! Chance roll from the character's risk stat (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007F434 (src/BATTLE/BATTLE.PRG/146C.c)
/// Rolls against a chance derived from the character's risk; returns 1 when the roll succeeds.
pub fn func_8007F434() callconv(.c) c_int {
    const character = v.g.vs_battle_characterState().*.?;
    const stats = psx.get(character.stats).?;
    var s0: c_int = @divTrunc((@as(c_int, stats.risk) +% 150) *% 100, 256);
    if (s0 > 100) {
        s0 = 100;
    }
    const roll = c.vs_main_getRand(100);
    return @intFromBool(roll < s0 +% 20);
}
