//! Battle unit 146C: stores a 16-bit value in D_800F1BA4 (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8008B4BC (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores its argument, truncated to 16 bits, in D_800F1BA4.
pub fn func_8008B4BC(arg0: c_int) callconv(.c) void {
    v.g.D_800F1BA4().* = psx.conv(u16, arg0);
}
