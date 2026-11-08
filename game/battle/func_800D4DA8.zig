//! Stub battle function that ignores its argument and returns 1 (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: func_800D4DA8 (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns 1 and does nothing else; the argument is unused.
pub fn func_800D4DA8(_: ?*v.D_800F53B8_t) callconv(.c) c_int {
    return 1;
}
