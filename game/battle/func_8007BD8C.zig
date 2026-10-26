//! Battle unit 146C: selects one of two engine toggles by its argument (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007BD8C (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls the two toggles with 1 and 0 for a nonzero argument, 0 and 1 otherwise, and returns the argument.
pub fn func_8007BD8C(arg0: c_int) callconv(.c) c_int {
    if (arg0 != 0) {
        c.func_800CB654(1);
        _ = c.func_8008B4C8(0);
    } else {
        c.func_800CB654(0);
        _ = c.func_8008B4C8(1);
    }
    return arg0;
}
