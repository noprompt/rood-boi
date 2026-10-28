//! Clears a battle global in the 146C unit (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007C4D4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets D_800F19A0 to zero.
pub fn func_8007C4D4() callconv(.c) void {
    v.g.D_800F19A0().* = 0;
}
