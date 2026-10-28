//! Reads the battle global D_800F1A2C (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DE78 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the 16-bit value of the global D_800F1A2C.
pub fn func_8007DE78() callconv(.c) c_short {
    return v.g.D_800F1A2C().*;
}
