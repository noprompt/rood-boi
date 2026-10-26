//! Battle camera roll setter (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: vs_battle_setCameraRoll (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the battle camera's roll, the Z component of its angles.
pub fn setCameraRoll(arg0: c_int) callconv(.c) void {
    v.g.vs_scratch().camera.angles.vz = arg0;
}
