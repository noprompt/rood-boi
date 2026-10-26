//! Copies a camera position into the battle scratchpad camera (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: vs_battle_setCameraPosition (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the scratchpad camera position to the given vector, x, y and z only.
pub fn setCameraPosition(inPosition: ?*v.VECTOR) callconv(.c) void {
    const scratch = v.g.vs_scratch();
    const position = inPosition.?;
    scratch.camera.position.vx = position.vx;
    scratch.camera.position.vy = position.vy;
    scratch.camera.position.vz = position.vz;
}
