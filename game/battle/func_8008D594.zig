//! Stores a one-byte battle flag (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: func_8008D594 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Stores the low byte of its argument in D_800F1D6E.
pub fn func_8008D594(arg0: c_int) callconv(.c) void {
    v.g.D_800F1D6E().* = psx.conv(i8, arg0);
}
