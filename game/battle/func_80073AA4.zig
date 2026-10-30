//! Sets the battle state word D_800F196C and calls func_8006C350 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80073AA4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores 0xB in D_800F196C, then calls func_8006C350.
pub fn func_80073AA4() callconv(.c) void {
    v.g.D_800F196C().* = 0xB;
    c.func_8006C350();
}
