//! Sets the projection distance and the geometry screen from it (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_setProjectionDistance (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores the projection distance and passes it to the GTE screen geometry setup.
pub fn setProjectionDistance(projectionDistance: c_int) callconv(.c) void {
    v.g.vs_main_projectionDistance().* = projectionDistance;
    c.SetGeomScreen(projectionDistance);
}
