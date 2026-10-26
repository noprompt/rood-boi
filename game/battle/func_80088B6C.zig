//! Battle unit 146C: a pass-through to func_80088554 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_80088B6C (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the result of func_80088554.
pub fn func_80088B6C() callconv(.c) c_int {
    return c.func_80088554();
}
