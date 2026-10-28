//! Largest absolute value of three ints (src/BATTLE/BATTLE.PRG/5BF94.c).

/// orig: _absMax3 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns the argument with the largest magnitude, as the C picks it (the last one on ties).
pub fn absMax3(arg0: c_int, arg1: c_int, arg2: c_int) callconv(.c) c_int {
    // -fwrapv: negating INT_MIN wraps to INT_MIN, so use wrapping negation.
    const t0: c_int = if (arg0 >= 0) arg0 else -%arg0;
    const a3: c_int = if (arg1 >= 0) arg1 else -%arg1;
    const v1: c_int = if (arg2 >= 0) arg2 else -%arg2;

    var result = arg0;
    var v0: bool = undefined;
    if (t0 < a3) {
        v0 = a3 < v1;
        result = arg1;
    } else {
        v0 = t0 < v1;
    }
    if (v0) {
        result = arg2;
    }
    return result;
}
