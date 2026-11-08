//! Clears the battle global D_800E8498 (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_80088CA0 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Clears the global D_800E8498 to zero.
pub fn func_80088CA0() callconv(.c) void {
    v.g.D_800E8498().* = 0;
}
