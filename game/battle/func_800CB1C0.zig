//! Battle state helper: calls func_800CACD0(7, 2), then stores a byte and sets a flag bit
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CB1C0 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Calls func_800CACD0(7, 2), stores `arg0 + 0x40` in D_800F4E6B and sets bit 0x400 of D_800F4EA0.
pub fn func_800CB1C0(arg0: c_int) callconv(.c) void {
    _ = c.func_800CACD0(7, 2);
    v.g.D_800F4E6B().* = psx.conv(u8, @as(c_int, arg0) +% 0x40);
    v.g.D_800F4EA0().* |= 0x400;
}
