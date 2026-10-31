//! Sets the battle state word D_800F196C to 6 and calls func_8006C39C (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007352C (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the battle state word to 6, then runs the routine that follows it.
pub fn func_8007352C() callconv(.c) void {
    v.g.D_800F196C().* = 6;
    c.func_8006C39C();
}
