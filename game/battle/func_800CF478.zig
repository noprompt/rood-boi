//! Stores its argument in the global D_800F531C (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: func_800CF478 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Sets the global D_800F531C to `arg0`.
pub fn func_800CF478(arg0: c_int) callconv(.c) void {
    v.g.D_800F531C().* = psx.conv(u32, arg0);
}
