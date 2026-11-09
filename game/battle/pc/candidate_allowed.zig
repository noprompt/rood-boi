//! Whether a candidate is allowed now (D2: 73460.s; oracle pc/src/battle_movement.c).
const ai = @import("views_71618");
const c = @import("c_battle_movement");
const psx = @import("common").psx;

/// orig: func_800DBCB4 (pc/src/battle_movement.c)
/// Candidate allowed now: not while the halfword at 0x90 is set, and not when
/// func_800DBC60 holds and the timer at 0x13F is running.
pub fn candidateAllowed(state: *ai.vs_battle_aiState, candidate: [*]u8) callconv(.c) c_int {
    if (state.unk90 != 0) return 0;
    if (c.func_800DBC60(state, candidate) == 0) return 1;
    return @intFromBool(state.minDelay == 0);
}
