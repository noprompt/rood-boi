//! Adds the smaller of two signed deltas to a base value (src/BATTLE/BATTLE.PRG/146C.c).

/// orig: _addMinDelta (src/BATTLE/BATTLE.PRG/146C.c)
/// Adds `a` or `b` to `base`, choosing between them by sign and zero tests, with wrapping addition.
pub fn addMinDelta(base: c_int, a: c_int, b: c_int) callconv(.c) c_int {
    var r: c_int = base;
    if (b < 0) {
        if (a >= b) {
            if (a != 0) {
                r +%= a;
            } else {
                r +%= b;
            }
        } else {
            r +%= b;
        }
    } else if ((b >= a) and (a != 0)) {
        r +%= a;
    } else {
        r +%= b;
    }
    return r;
}
