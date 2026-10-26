//! Stores its argument in the battle global D_800F1A2C (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8007DDAC (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores its argument in D_800F1A2C, truncated to a halfword.
pub fn func_8007DDAC(arg0: c_int) callconv(.c) void {
    v.g.D_800F1A2C().* = psx.conv(i16, arg0);
}
