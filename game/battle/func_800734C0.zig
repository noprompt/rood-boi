//! Battle setup step: resets the 16 battle slots, then sets the state word (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_800734C0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Resets each of the 16 battle slots, clears the second reset call, then sets D_800F196C to 10.
pub fn func_800734C0() callconv(.c) void {
    var i: c_int = 0;
    while (i < 16) : (i +%= 1) {
        c.func_8009E5C4(i);
    }
    c.func_8007C0AC(0, 2);
    v.g.D_800F196C().* = 10;
}
