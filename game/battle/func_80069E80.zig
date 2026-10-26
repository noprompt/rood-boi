//! Finds the battle slot entry whose first byte matches `arg0 + 1`
//! (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: func_80069E80 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the last of the current block's eight 40-byte entries whose first byte is `arg0 + 1`, or null.
pub fn func_80069E80(arg0: c_int) callconv(.c) ?*anyopaque {
    var found: ?*anyopaque = null;
    // D_80060064 is not checked against the array's bounds, as in the original.
    const block = psx.at(v.g.D_80061078(), v.g.D_80060064().*);
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        if (@as(c_int, block.unk8[i][0]) == arg0 +% 1) {
            found = &block.unk8[i];
        }
    }
    return found;
}
