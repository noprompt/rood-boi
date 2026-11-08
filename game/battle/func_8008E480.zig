//! Battle unit 146C: forwards its argument to two battle helpers
//! (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8008E480 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_800938AC and then func_800918E8 with the same argument.
pub fn func_8008E480(arg0: c_int) callconv(.c) void {
    c.func_800938AC(arg0);
    c.func_800918E8(arg0);
}
