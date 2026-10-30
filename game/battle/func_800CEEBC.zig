//! Checks a battle state window and reports whether a counter is nonzero
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: func_800CEEBC (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns 1 when D_800F531C - 4 is below 2 and D_800F5224 > D_800F5228 and D_800F521C is nonzero, else 0.
pub fn func_800CEEBC() callconv(.c) c_int {
    var var_a1: c_int = 0;
    if (((v.g.D_800F531C().* -% 4) < 2) and (v.g.D_800F5224().* > v.g.D_800F5228().*)) {
        var_a1 = @intFromBool(v.g.D_800F521C().* > 0);
    }
    return var_a1;
}
