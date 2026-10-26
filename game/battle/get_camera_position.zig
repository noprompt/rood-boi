//! Camera position readout for the battle overlay (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: vs_battle_getCameraPosition (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the scratchpad camera's position vector into `outPosition`.
pub fn getCameraPosition(outPosition: ?*v.VECTOR) callconv(.c) void {
    const out = outPosition.?;
    const position = &v.g.vs_scratch().camera.position;
    out.vx = position.vx;
    out.vy = position.vy;
    out.vz = position.vz;
}
