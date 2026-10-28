//! Poison hit prerequisite: whether the poison effect can be applied (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyPoison (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when effect 14 (poison) can be applied to the target `arg1`, else 0.
pub fn hitPrerequisiteCanApplyPoison(_: ?*anyopaque, arg1: [*c]u8) callconv(.c) c_int {
    return @as(c_int, @intFromBool(c._hitPrerequisiteCanApplyEffect(14, arg1) == 0));
}
