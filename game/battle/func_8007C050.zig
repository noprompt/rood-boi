//! Calls the per-slot helper for slots 0 to 15 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007C050 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs func_8007BFF8 for each of the 16 slots, in order.
pub fn func_8007C050() callconv(.c) void {
    var i: c_int = 0;
    while (i < 16) : (i +%= 1) {
        c.func_8007BFF8(i);
    }
}
