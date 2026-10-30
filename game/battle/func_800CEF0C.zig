//! Reads the battle value at D_800F5224 when D_800F531C is 4 or 5, else 0 (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: func_800CEF0C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns D_800F5224 while D_800F531C is 4 or 5 (unsigned range check), else 0.
pub fn func_800CEF0C() callconv(.c) c_int {
    var result: c_int = 0;
    if ((v.g.D_800F531C().* -% 4) < 2) {
        result = v.g.D_800F5224().*;
    }
    return result;
}
