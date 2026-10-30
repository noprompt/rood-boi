//! A one-byte store into a battle global (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8008EAF8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores its argument, truncated to a byte, in D_800F1DC9.
pub fn func_8008EAF8(value: c_int) callconv(.c) void {
    v.g.D_800F1DC9().* = psx.conv(u8, value);
}
