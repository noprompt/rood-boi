//! Clears the battle flag D_800F185C after handing its value to func_8007B29C
//! (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8006D064 (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_8007B29C with the flag D_800F185C, then clears the flag.
pub fn func_8006D064() callconv(.c) void {
    c.func_8007B29C(8, 4, v.g.D_800F185C().*, 0, 0, 0);
    v.g.D_800F185C().* = 0;
}
