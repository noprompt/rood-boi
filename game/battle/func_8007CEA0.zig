//! Forwards its argument to func_8009E5C4 (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007CEA0 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Passes its argument on to func_8009E5C4.
pub fn func_8007CEA0(arg0: c_int) callconv(.c) void {
    c.func_8009E5C4(arg0);
}
