//! Prerequisite check for the AGL-down hit effect (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyAglDown (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when effect 9 cannot be applied to the target, else 0.
pub fn hitPrerequisiteCanApplyAglDown(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    const result = c._hitPrerequisiteCanApplyEffect(9, arg1);
    return @as(c_int, @intFromBool(result == 0));
}
