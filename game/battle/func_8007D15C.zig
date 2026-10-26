//! Calls the slot routine func_8007D08C for slots 1 to 15 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007D15C (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs func_8007D08C for each slot 1 to 15, then returns its argument.
pub fn func_8007D15C(arg0: c_int) callconv(.c) c_int {
    var i: c_int = 1;
    while (i < 16) : (i += 1) {
        _ = c.func_8007D08C(i, arg0);
    }
    return arg0;
}
