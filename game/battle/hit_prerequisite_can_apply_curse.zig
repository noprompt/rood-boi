//! Curse hit prerequisite: whether the curse effect (16) can apply
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyCurse (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the prerequisite check for effect 16 (curse) passes, else 0.
pub fn hitPrerequisiteCanApplyCurse(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @intFromBool(c._hitPrerequisiteCanApplyEffect(16, arg1) == 0);
}
