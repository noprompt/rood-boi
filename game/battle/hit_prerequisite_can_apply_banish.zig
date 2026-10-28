//! Banish's hit prerequisite: the effect check for effect 29 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");
const v = @import("views_146C");

/// orig: _hitPrerequisiteCanApplyBanish (src/BATTLE/BATTLE.PRG/146C.c)
/// Reports whether banish (effect 29) can apply: the effect check returns 0.
pub fn hitPrerequisiteCanApplyBanish(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @intFromBool(c._hitPrerequisiteCanApplyEffect(29, arg1) == 0);
}
