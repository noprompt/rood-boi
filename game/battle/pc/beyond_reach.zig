//! Reach test (D2: 7C7B0.s; oracle pc/src/battle_movement.c).
const ai = @import("views_71618");
const psx = @import("common").psx;

/// orig: func_800E4FB0 (pc/src/battle_movement.c)
/// Whether the distance recorded for actor `id` (0x1E4 + id * 4) is above 100
/// (unsigned). The original adds 0x80 to `range` for model class 10 but then
/// squares its constant 10 instead, so `range` is not read.
pub fn beyondReach(state: *ai.vs_battle_aiState, id: c_int, range: c_int) callconv(.c) c_int {
    _ = range;
    return @intFromBool(100 < psx.fieldAt(c_uint, &state.tbl.t.distances, @as(isize, id) * 4).*);
}
