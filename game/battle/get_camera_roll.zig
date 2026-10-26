//! Current camera roll, the scratchpad camera's vz angle masked to 12 bits (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: vs_battle_getCameraRoll (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the camera roll: the scratchpad camera's vz angle in 12-bit units.
pub fn getCameraRoll() callconv(.c) c_int {
    return v.g.vs_scratch().camera.angles.vz & 0xFFF;
}
