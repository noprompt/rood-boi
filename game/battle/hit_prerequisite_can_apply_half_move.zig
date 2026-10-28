//! The half-move prerequisite check for a hit action (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyHalfMove (src/BATTLE/BATTLE.PRG/146C.c)
/// Passes when the effect-4 prerequisite check returns 0 for the given argument.
pub fn hitPrerequisiteCanApplyHalfMove(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @intFromBool(c._hitPrerequisiteCanApplyEffect(4, arg1) == 0);
}
