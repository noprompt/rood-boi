//! An actor update state's action timer (D2: 6FA6C.s; oracle pc/src/battle_helpers.c).
const ai = @import("views_71618");
const c = @import("c_battle_helpers");

/// orig: func_800D8280 (pc/src/battle_helpers.c)
/// Counts down the byte timer at 0x12A (a zero timer is left alone). When it
/// reaches zero the state's actor (byte 0x88) is sent 0, otherwise the
/// halfword at 0x138.
pub fn tickActionTimer(state: *ai.vs_battle_aiState) callconv(.c) void {
    if (state.unk12A == 0) return;
    state.unk12A -= 1;
    const actor: c_int = state.id;
    if (state.unk12A == 0) {
        _ = c.func_800D820C(actor, 0);
    } else {
        _ = c.func_800D820C(actor, state.unk138);
    }
}
