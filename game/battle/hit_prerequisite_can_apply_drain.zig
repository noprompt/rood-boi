//! Hit prerequisite for the drain action: the target must not resist effect 30 and must not be undead (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyDrain (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when effect 30 cannot be applied to the target and its class is not undead, else 0.
pub fn hitPrerequisiteCanApplyDrain(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    if (c._hitPrerequisiteCanApplyEffect(30, arg1) == 0 and
        c._getEnemyClass(arg1) != c.enemyClassUndead)
    {
        return 1;
    }
    return 0;
}
