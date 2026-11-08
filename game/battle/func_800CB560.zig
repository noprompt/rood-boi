//! Clears the lower-screen UI state (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: func_800CB560 (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// Clears the lower-screen UI state.
pub fn func_800CB560() callconv(.c) void {
    v.g.vs_battle_lowerScreenUiState().* = 0;
}
