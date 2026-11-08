//! Clears the battle flag byte D_800F522C (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: func_800CF920 (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// Clears the battle flag byte D_800F522C.
pub fn func_800CF920() callconv(.c) void {
    v.g.D_800F522C().* = 0;
}
