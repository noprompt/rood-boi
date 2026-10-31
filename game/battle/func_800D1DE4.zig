//! Sets flag bits in the battle global D_800F5518 (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");

/// orig: func_800D1DE4 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Sets the bits of `arg0` in the flag byte D_800F5518.
pub fn func_800D1DE4(arg0: c_int) callconv(.c) void {
    const flags = v.g.D_800F5518();
    flags.* = psx.conv(u8, @as(c_int, flags.*) | arg0);
}
