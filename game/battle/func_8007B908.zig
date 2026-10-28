//! Calls func_8007B63C when the low two bits of D_800F1868 are clear (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007B908 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the step routine (func_8007B63C) when the low two bits of D_800F1868 are clear.
pub fn func_8007B908() callconv(.c) void {
    if ((v.g.D_800F1868().* & 3) == 0) {
        c.func_8007B63C();
    }
}
