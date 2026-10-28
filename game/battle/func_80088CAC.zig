//! Battle frame step: runs func_8007BCCC when the phase byte is 2, then func_80069DBC (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80088CAC (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the phase-2 step when D_80050468's phase is 2, then the common step.
pub fn func_80088CAC() callconv(.c) void {
    if (v.g.D_80050468().unk2 == 2) {
        c.func_8007BCCC();
    }
    c.func_80069DBC();
}
