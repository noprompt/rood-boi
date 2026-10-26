//! Stores a byte in D_800F1CD6 and returns it (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8008B4C8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the byte at D_800F1CD6 to arg0 and returns the stored value.
pub fn func_8008B4C8(arg0: u8) callconv(.c) c_int {
    const stored = v.g.D_800F1CD6();
    stored.* = arg0;
    return @as(c_int, stored.*);
}
