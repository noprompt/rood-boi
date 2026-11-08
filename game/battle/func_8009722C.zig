//! Sets the battle flag D_800F227A (pc/src/game/BATTLE/BATTLE.PRG/2842C.c).
const v = @import("views_2842C");

/// orig: func_8009722C (pc/src/game/BATTLE/BATTLE.PRG/2842C.c)
/// Sets the flag D_800F227A to 1.
pub fn func_8009722C() callconv(.c) void {
    v.g.D_800F227A().* = 1;
}
