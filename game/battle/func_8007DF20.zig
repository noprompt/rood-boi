//! Returns the battle global D_800F1A44 (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: func_8007DF20 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the value of D_800F1A44 as an int.
pub fn func_8007DF20() callconv(.c) c_int {
    return psx.conv(c_int, v.g.D_800F1A44().*);
}
