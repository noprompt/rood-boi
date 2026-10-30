//! Stores two halfword globals of the battle overlay (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8008EAE4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores the two arguments into D_800F1DB8 and D_800F1DBA, truncated to halfwords.
pub fn func_8008EAE4(arg0: c_int, arg1: c_int) callconv(.c) void {
    v.g.D_800F1DB8().* = psx.conv(i16, arg0);
    v.g.D_800F1DBA().* = psx.conv(i16, arg1);
}
