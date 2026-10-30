//! Battle flag setup and a call into func_8007B764 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");
const v = @import("views_146C");

/// orig: func_8007B9CC (src/BATTLE/BATTLE.PRG/146C.c)
/// Clears D_800F1860, sets D_800F1864, then calls func_8007B764.
pub fn func_8007B9CC() callconv(.c) void {
    v.g.D_800F1860().* = 0;
    v.g.D_800F1864().* = 1;
    c.func_8007B764();
}
