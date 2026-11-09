//! An actor's two flag bytes (D2: 7E028.s; oracle pc/src/battle_helpers.c).

const ai = @import("views_71618");
/// orig: func_800E6828 (pc/src/battle_helpers.c)
/// Merges the actor's flag halfword at 0x224 with its own high byte (flags |=
/// flags >> 8), stores the result at 0x15E, and sets byte 0x125 to 1 when
/// any of bits 4-5 is set, else 2 when bit 3 is, else 0.
pub fn mergeActorFlags(state: *ai.vs_battle_aiState) callconv(.c) void {
    var flags: u32 = @as(u32, state.field224) | (@as(u32, state.field225) << 8);
    flags |= flags >> 8;
    state.flags = @truncate(flags);
    state.unk125 = if (flags & 0x30 != 0) 1 else if (flags & 8 != 0) 2 else 0;
}
