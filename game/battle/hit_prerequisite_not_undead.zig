//! Hit prerequisite: passes unless the target is undead (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");
const v = @import("views_146C");

/// orig: _hitPrerequisiteNotUndead (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the target's enemy class is not undead, else 0; the action is unused.
pub fn hitPrerequisiteNotUndead(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    return @intFromBool(c._getEnemyClass(arg1) != c.enemyClassUndead);
}
