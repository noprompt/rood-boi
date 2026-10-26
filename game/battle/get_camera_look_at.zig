//! Reads the battle camera's look-at point into an output vector (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: vs_battle_getCameraLookAt (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the scratchpad camera's look-at point (x, y, z) into `outLookAt`.
pub fn getCameraLookAt(outLookAt: ?*v.VECTOR) callconv(.c) void {
    const out = outLookAt.?;
    const look = &v.g.vs_scratch().camera.lookAt;
    out.vx = look.vx;
    out.vy = look.vy;
    out.vz = look.vz;
}
