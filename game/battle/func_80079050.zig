//! Clears the battle state when the current action slot is free (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80079050 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the two cleanup calls once the action slot at the current index reports free.
pub fn func_80079050() callconv(.c) void {
    const d = v.g.D_800F19CC().*.?;
    const index: usize = d.unk0 & 3;
    if (c.func_800DEC88(&d.unk854[index]) == 0) {
        _ = c.func_80069D14();
        _ = c.func_8006FCBC();
    }
}
