//! Hit prerequisite: whether a silence effect can be applied to the target
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplySilence (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the effect check for silence (effect 12) passes, else 0.
pub fn hitPrerequisiteCanApplySilence(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @as(c_int, @intFromBool(c._hitPrerequisiteCanApplyEffect(12, arg1) == 0));
}
