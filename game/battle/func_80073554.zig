//! Sets D_800F196C and calls the routine at func_8006C40C (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80073554 (src/BATTLE/BATTLE.PRG/146C.c)
/// Raises the D_800F196C flag and runs func_8006C40C.
pub fn func_80073554() callconv(.c) void {
    v.g.D_800F196C().* = 1;
    c.func_8006C40C();
}
