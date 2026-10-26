//! Clears the battle flag table at D_800F19A8 and sets its first 25 entries to 0xFF (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DF48 (src/BATTLE/BATTLE.PRG/146C.c)
/// Zeroes the 32-byte flag table, sets its first 25 entries to 0xFF, and clears D_800F18F8.
pub fn func_8007DF48() callconv(.c) void {
    const table = v.g.D_800F19A8();
    var i: usize = 0;
    while (i < 0x20) : (i += 1) {
        table[i] = 0;
    }
    i = 0;
    while (i < 0x19) : (i += 1) {
        table[i] = 0xFF;
    }
    v.g.D_800F18F8().* = 0;
}
