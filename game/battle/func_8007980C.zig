//! Battle unit 146C: runs func_8006FA20 when the low two bits of D_800F1868 are clear
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007980C (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_8006FA20 when the low two bits of D_800F1868 are both clear.
pub fn func_8007980C() callconv(.c) void {
    if ((v.g.D_800F1868().* & 3) == 0) {
        c.func_8006FA20();
    }
}
