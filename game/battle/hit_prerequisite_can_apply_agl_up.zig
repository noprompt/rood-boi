//! Ability prerequisite check: whether AGL up can apply (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");
const v = @import("views_146C");

/// orig: _hitPrerequisiteCanApplyAglUp (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the effect check for effect 10 passes (it returns 0), else 0.
pub fn hitPrerequisiteCanApplyAglUp(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @intFromBool(c._hitPrerequisiteCanApplyEffect(10, arg1) == 0);
}
