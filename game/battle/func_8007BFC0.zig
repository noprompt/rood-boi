//! Calls func_8007BF6C for each of the 16 slots (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007BFC0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs func_8007BF6C for slots 0 through 15, in order.
pub fn func_8007BFC0() callconv(.c) void {
    var i: c_int = 0;
    while (i < 16) : (i +%= 1) {
        c.func_8007BF6C(i);
    }
}
