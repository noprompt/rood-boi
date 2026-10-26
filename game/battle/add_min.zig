//! Adds the smaller or larger of two battle values to a base (src/BATTLE/BATTLE.PRG/146C.c).

/// orig: _add_min (src/BATTLE/BATTLE.PRG/146C.c)
/// Adds one of `a` and `b` to `base`, chosen as the original's signed comparisons pick it.
pub fn add_min(base: c_int, a: c_int, b: c_int) callconv(.c) c_int {
    const addend: c_int = if (b < 0)
        (if (a < b) b else a)
    else
        (if (b < a) b else a);
    return base +% addend;
}
