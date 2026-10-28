//! Prerequisite check for the Numbness action (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");
const v = @import("views_146C");

/// orig: _hitPrerequisiteCanApplyNumbness (src/BATTLE/BATTLE.PRG/146C.c)
/// Numbness can be applied when the effect prerequisite check for effect 15 returns 0.
pub fn hitPrerequisiteCanApplyNumbness(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @intFromBool(c._hitPrerequisiteCanApplyEffect(15, arg1) == 0);
}
