//! Clears the battle pointer D_800F1ABC and runs func_8007D360 (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007D3F8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Clears D_800F1ABC to NULL, then runs func_8007D360.
pub fn func_8007D3F8() callconv(.c) void {
    psx.put(v.g.D_800F1ABC(), null);
    c.func_8007D360();
}
