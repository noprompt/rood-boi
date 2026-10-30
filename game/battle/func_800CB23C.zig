//! Battle helper: runs func_800CACD0(0xF, 2) and sets D_800F4FDB to 1 (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CB23C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Calls the menu state handler with 0xF and flags D_800F4FDB.
pub fn func_800CB23C() callconv(.c) void {
    _ = c.func_800CACD0(0xF, 2);
    v.g.D_800F4FDB().* = 1;
}
