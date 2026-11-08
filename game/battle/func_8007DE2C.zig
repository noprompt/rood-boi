//! Stores its argument in the battle global D_800F1B9C (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DE2C (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Stores its argument in D_800F1B9C.
pub fn func_8007DE2C(arg0: c_int) callconv(.c) void {
    v.g.D_800F1B9C().* = arg0;
}
