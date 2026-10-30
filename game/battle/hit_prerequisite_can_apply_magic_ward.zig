//! Magic ward prerequisite: whether the ward effect (18) can be applied to the target
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyMagicWard (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the magic ward effect (18) can be applied to `arg1`, else 0.
pub fn hitPrerequisiteCanApplyMagicWard(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @intFromBool(c._hitPrerequisiteCanApplyEffect(18, arg1) == 0);
}
