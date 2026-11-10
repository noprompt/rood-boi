//! The room's height limit (D2: 7E05C.s; oracle pc/src/actor_cleanup.c).
const v = @import("views_actor_cleanup");
const psx = @import("common").psx;

/// orig: func_800E75EC (pc/src/actor_cleanup.c)
/// Word 0x14 of the D_800F58BC record, or 0 when no record is loaded.
pub fn roomHeightLimit() callconv(.c) c_int {
    return if (v.g.D_800F58BC().*) |room| room.unk14 else 0;
}
