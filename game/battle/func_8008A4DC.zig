//! Sets the battle global D_800F190C from a flag (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8008A4DC (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores 1 in D_800F190C when arg0 is nonzero, else 0.
pub fn func_8008A4DC(arg0: c_int) callconv(.c) void {
    v.g.D_800F190C().* = if (arg0 != 0) 1 else 0;
}
