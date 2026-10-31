//! Clears a battle global (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8008B4B0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Clears the battle global D_800F1BB6.
pub fn func_8008B4B0() callconv(.c) void {
    v.g.D_800F1BB6().* = 0;
}
