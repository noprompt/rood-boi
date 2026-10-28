//! Hit prerequisite for the Int Up action (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyIntUp (src/BATTLE/BATTLE.PRG/146C.c)
/// Int Up can apply when the effect check for effect 8 returns 0.
pub fn hitPrerequisiteCanApplyIntUp(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @as(c_int, @intFromBool(c._hitPrerequisiteCanApplyEffect(8, arg1) == 0));
}
