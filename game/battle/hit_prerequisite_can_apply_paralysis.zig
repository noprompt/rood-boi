//! Paralysis hit prerequisite: the generic effect check for effect 13 must pass
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyParalysis (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when paralysis can be applied, i.e. the effect check for effect 13 returns 0.
pub fn hitPrerequisiteCanApplyParalysis(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @as(c_int, @intFromBool(c._hitPrerequisiteCanApplyEffect(13, arg1) == 0));
}
