//! Sets the battle global D_800EBC78 to 1 (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: func_800C9F88 (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// Sets the global D_800EBC78 to 1.
pub fn func_800C9F88() callconv(.c) void {
    v.g.D_800EBC78().* = 1;
}
