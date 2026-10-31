//! Sets the lower screen UI state to 1 (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");

/// orig: func_800CB550 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Marks the lower battle screen UI state as 1.
pub fn func_800CB550() callconv(.c) void {
    v.g.vs_battle_lowerScreenUiState().* = 1;
}
