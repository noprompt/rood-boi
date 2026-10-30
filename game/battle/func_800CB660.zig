//! Stores a value into the battle global D_800EB9CC (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: func_800CB660 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Stores the low byte of `arg0` in D_800EB9CC.
pub fn func_800CB660(arg0: c_int) callconv(.c) void {
    v.g.D_800EB9CC().* = psx.conv(u8, arg0);
}
