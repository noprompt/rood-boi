//! Strength-down hit prerequisite: whether the effect check for code 5 passes (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyStrDown (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the effect check for code 5 (strength down) passes for the hit, else 0.
pub fn hitPrerequisiteCanApplyStrDown(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @as(c_int, @intFromBool(c._hitPrerequisiteCanApplyEffect(5, arg1) == 0));
}
