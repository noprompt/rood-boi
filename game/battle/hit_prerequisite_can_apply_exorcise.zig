//! Exorcise's hit prerequisite: applies to undead targets that effect 30 does not cover (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyExorcise (src/BATTLE/BATTLE.PRG/146C.c)
/// Exorcise can be applied when effect 30 cannot and the target is undead.
pub fn hitPrerequisiteCanApplyExorcise(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    if (c._hitPrerequisiteCanApplyEffect(30, arg1) == 0 and c._getEnemyClass(arg1) == c.enemyClassUndead) {
        return 1;
    }
    return 0;
}
