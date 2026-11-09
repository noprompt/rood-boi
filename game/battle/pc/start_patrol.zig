//! Starting a waypoint patrol (D2: 72B70.s; oracle pc/src/battle_movement.c).
const ai = @import("views_71618");
const c = @import("c_battle_movement");

/// orig: func_800DB5FC (pc/src/battle_movement.c)
/// Enters movement mode 5 and patrols its waypoints (func_800E23AC). The
/// assembly skips both when $a2 is 0; the port always patrols (the oracle's
/// choice: its only caller passes no such argument).
pub fn startPatrol(state: *ai.vs_battle_aiState) callconv(.c) void {
    _ = c.func_800DB4AC(state, 5);
    c.func_800E23AC(state);
}
