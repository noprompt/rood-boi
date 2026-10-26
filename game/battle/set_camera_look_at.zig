//! The camera look-at point setter (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: vs_battle_setCameraLookAt (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the camera look-at point from `inLookAt` into the scratchpad camera, one component at a time.
pub fn setCameraLookAt(inLookAt: ?*v.VECTOR) callconv(.c) void {
    const lookAt = &v.g.vs_scratch().camera.lookAt;
    lookAt.vx = inLookAt.?.vx;
    lookAt.vy = inLookAt.?.vy;
    lookAt.vz = inLookAt.?.vz;
}
