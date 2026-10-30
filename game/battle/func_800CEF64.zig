//! Battle flag query: reports whether D_800F54A8 is set (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: func_800CEF64 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns 1 when the battle flag D_800F54A8 is nonzero, else 0.
pub fn func_800CEF64() callconv(.c) c_int {
    return @intFromBool(v.g.D_800F54A8().* != 0);
}
