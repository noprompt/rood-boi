//! Clears the 0xFE and 0xFD markers in the 32-byte table D_800F19A8
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DF98 (src/BATTLE/BATTLE.PRG/146C.c)
/// Maps marker 0xFE in D_800F19A8[0..32] to 0 and marker 0xFD to 0xFE.
pub fn func_8007DF98() callconv(.c) void {
    const table = v.g.D_800F19A8();
    var i: usize = 0;
    while (i < 32) : (i += 1) {
        if (table[i] == 0xFE) {
            table[i] = 0;
        }
        if (table[i] == 0xFD) {
            // C stores -2 into a u8 element: 0xFE.
            table[i] = 0xFE;
        }
    }
}
