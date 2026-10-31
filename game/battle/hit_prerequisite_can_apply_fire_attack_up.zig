//! Fire attack-up hit prerequisite: the target has no effect 22 and wields a weapon with a blade
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyFireAttackUp (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when effect 22 cannot be applied to the actor at `arg1` and its weapon has a blade, else 0.
pub fn hitPrerequisiteCanApplyFireAttackUp(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    if (c._hitPrerequisiteCanApplyEffect(22, arg1) == 0) {
        const actor = v.g.vs_battle_actors()[arg1[0]].?;
        const stats = psx.get(actor.stats).?;
        if (stats.weapon.blade.id != 0) {
            return 1;
        }
    }
    return 0;
}
