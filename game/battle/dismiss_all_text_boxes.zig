//! Dismisses every battle text box and reports whether all of them closed
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const c = @import("c_5BF94");

/// orig: _dismissAllTextBoxes (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Dismisses text boxes 0 to 7 in order; returns 0 if any dismissal reported failure, else 1.
pub fn dismissAllTextBoxes() callconv(.c) c_int {
    var var_s1: c_int = 1;
    var i: c_int = 0;
    while (i < 8) : (i +%= 1) {
        if (c.vs_battle_dismissTextBox(i) != 0) {
            var_s1 = 0;
        }
    }
    return var_s1;
}
