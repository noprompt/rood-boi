//! Hit prerequisite for undead targets (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteUndead (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the class of the target named by `arg1` is undead, else 0.
pub fn hitPrerequisiteUndead(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @intFromBool(c._getEnemyClass(arg1) == c.enemyClassUndead);
}
