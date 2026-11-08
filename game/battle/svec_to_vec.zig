//! SVECTOR to VECTOR (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: vs_battle_svecToVec (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// Copies x, y, z, sign-extended.
pub fn svecToVec(from: ?*v.SVECTOR, to: ?*v.VECTOR) callconv(.c) void {
    to.?.vx = from.?.vx;
    to.?.vy = from.?.vy;
    to.?.vz = from.?.vz;
}
