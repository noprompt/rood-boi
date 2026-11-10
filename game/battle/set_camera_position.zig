//! Copies a camera position into the battle scratchpad camera (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: vs_battle_setCameraPosition (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Sets the scratchpad camera position to the given vector, x, y and z only.
pub fn setCameraPosition(inPosition: ?*v.VECTOR) callconv(.c) void {
    const view = v.g.vs_view();
    const position = inPosition.?;
    view.camera.position.vx = position.vx;
    view.camera.position.vy = position.vy;
    view.camera.position.vz = position.vz;
}
