//! Battle unit 146C's wrapper that forwards to func_80089D04 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007C424 (src/BATTLE/BATTLE.PRG/146C.c)
/// Forwards to func_80089D04 and returns nothing.
pub fn func_8007C424() callconv(.c) void {
    c.func_80089D04();
}
