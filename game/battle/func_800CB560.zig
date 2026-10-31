//! Clears the lower-screen UI state (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: func_800CB560 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Clears the lower-screen UI state.
pub fn func_800CB560() callconv(.c) void {
    v.g.vs_battle_lowerScreenUiState().* = 0;
}
