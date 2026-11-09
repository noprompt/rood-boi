//! Movement flag word (D2: 7BDD4.s; oracle pc/src/battle_movement.c).
const ai = @import("views_71618");
const psx = @import("common").psx;

/// orig: func_800E4BB8 (pc/src/battle_movement.c)
/// Rebuilds the movement flags at 0x190: keeps the bits outside 0xFE1 (mask
/// 0xFFFFF01E) and sets 0x3C0 when the byte at 0x23 is nonzero.
pub fn rebuildMovementFlags(state: *ai.vs_battle_aiState) callconv(.c) void {
    var flags: c_uint = state.movementFlags.raw & 0xfffff01e;
    if (state.f23 != 0) flags |= 0x3c0;
    state.movementFlags.raw = flags;
}
