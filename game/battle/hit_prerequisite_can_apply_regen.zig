//! Hit prerequisite check for the regen effect (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");
const v = @import("views_146C");

/// orig: _hitPrerequisiteCanApplyRegen (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when effect 17 (regen) passes its prerequisite check, else 0.
pub fn hitPrerequisiteCanApplyRegen(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @as(c_int, @intFromBool(c._hitPrerequisiteCanApplyEffect(17, arg1) == 0));
}
