//! Hit-prerequisite check for the Strength Up effect (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyStrUp (src/BATTLE/BATTLE.PRG/146C.c)
/// Whether the Strength Up effect (code 6) can apply to the target: 1 if the effect check returns 0.
pub fn hitPrerequisiteCanApplyStrUp(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @as(c_int, @intFromBool(c._hitPrerequisiteCanApplyEffect(6, arg1) == 0));
}
