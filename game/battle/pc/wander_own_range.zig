//! Wandering around the state's own tile (D2: 72B70.s; oracle pc/src/battle_movement.c).
const ai = @import("views_71618");
const c = @import("c_battle_movement");
const psx = @import("common").psx;

/// orig: func_800DB5B0 (pc/src/battle_movement.c)
/// Wanders (func_800DB5B8) with the state's own tile (0xCC) and range (0xC8).
pub fn wanderOwnRange(state: *ai.vs_battle_aiState) callconv(.c) void {
    c.func_800DB5B8(state, @bitCast(@as(*align(1) const u32, @ptrCast(&state.fCC)).*), @bitCast(state.fC8));
}
