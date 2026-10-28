//! Clears the two battle counters at D_800F1860/D_800F1864, then runs func_8007B7DC
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007B9A0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Resets the two counters at D_800F1860 and D_800F1864, then calls func_8007B7DC.
pub fn func_8007B9A0() callconv(.c) void {
    v.g.D_800F1860().* = 0;
    v.g.D_800F1864().* = 0;
    c.func_8007B7DC();
}
