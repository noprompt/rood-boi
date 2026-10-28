//! Larger-magnitude helper: picks whichever argument has the bigger absolute value
//! (src/BATTLE/BATTLE.PRG/5BF94.c).

/// orig: _absMax2 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns `b` if its absolute value is at least that of `a`, else `a`.
pub fn absMax2(a: c_int, b: c_int) callconv(.c) c_int {
    // -fwrapv: negating INT_MIN wraps to INT_MIN.
    const absA: c_int = if (a >= 0) a else -%a;
    const absB: c_int = if (b < 0) -%b else b;
    if (absA < absB) {
        return b;
    }
    return a;
}
