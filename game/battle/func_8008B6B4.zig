//! Clears the two battle counters at D_800F1D6A/D_800F1D6C and the table at D_800F1D28 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008B6B4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Resets the two counters and zeroes the eight-entry table they sit beside.
pub fn func_8008B6B4() callconv(.c) void {
    v.g.D_800F1D6A().* = 0;
    v.g.D_800F1D6C().* = 0;
    const table = v.g.D_800F1D28();
    c.vs_main_bzero(table, @sizeOf(@TypeOf(table.*)));
}
