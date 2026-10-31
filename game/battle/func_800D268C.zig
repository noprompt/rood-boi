//! Clears the battle global D_800F5600 (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: func_800D268C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Clears D_800F5600.
pub fn func_800D268C() callconv(.c) void {
    v.g.D_800F5600().* = 0;
}
