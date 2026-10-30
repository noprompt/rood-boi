//! Hit prerequisite for the water attack-up skill (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyWaterAttackUp (src/BATTLE/BATTLE.PRG/146C.c)
/// Passes when the effect-24 prerequisite holds and the target's weapon has a blade.
pub fn hitPrerequisiteCanApplyWaterAttackUp(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    if (c._hitPrerequisiteCanApplyEffect(24, arg1) == 0) {
        const actor = v.g.vs_battle_actors()[arg1.*].?;
        const stats = psx.get(actor.stats).?;
        if (stats.weapon.blade.id != 0) {
            return 1;
        }
    }
    return 0;
}
