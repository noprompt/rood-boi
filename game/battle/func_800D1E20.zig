//! Stores an argument in battle global D_800F55E8 (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");

/// orig: func_800D1E20 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Stores its argument in the global D_800F55E8.
pub fn func_800D1E20(arg0: c_int) callconv(.c) void {
    v.g.D_800F55E8().* = psx.conv(u32, arg0);
}
