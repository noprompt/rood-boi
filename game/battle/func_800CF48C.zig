//! Returns the battle word D_800F531C as an int (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: func_800CF48C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns the 32-bit word D_800F531C, converted to int as C does.
pub fn func_800CF48C() callconv(.c) c_int {
    return psx.conv(c_int, v.g.D_800F531C().*);
}
