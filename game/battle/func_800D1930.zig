//! Zeroes four battle globals and clears the first byte of each D_800F54B8 entry (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: func_800D1930 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Resets four battle globals to 0 and sets the unk0 byte of each of the four D_800F54B8 entries to 0xFF.
pub fn func_800D1930() callconv(.c) void {
    v.g.D_800F5518().* = 0;
    v.g.D_800F55E8().* = 0;
    v.g.D_800F54D0().* = 0;
    v.g.D_800F55A0().* = 0;

    const entries = v.g.D_800F54B8();
    var i: c_int = 0;
    while (i < 4) : (i +%= 1) {
        // i is 0..3 by the loop test, so the index is in range for the entries.
        entries[@intCast(i)].unk0 = 0xFF;
    }
}
