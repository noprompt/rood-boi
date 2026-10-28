//! Prerequisite check for the Int Down hit effect (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyIntDown (src/BATTLE/BATTLE.PRG/146C.c)
/// Whether the Int Down effect (effect 7) can apply to the target named by `target`.
pub fn hitPrerequisiteCanApplyIntDown(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @as(c_int, @intFromBool(c._hitPrerequisiteCanApplyEffect(7, arg1) == 0));
}
