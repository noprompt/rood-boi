//! Air Attack Up's prerequisite: the target has a weapon blade (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyAirAttackUp (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the effect check for target `arg1` passes (returns 0) and the target's weapon has a blade, else 0.
pub fn hitPrerequisiteCanApplyAirAttackUp(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    if (c._hitPrerequisiteCanApplyEffect(21, arg1) == 0) {
        const actor = v.g.vs_battle_actors()[arg1[0]].?;
        const stats = psx.get(actor.stats).?;
        if (stats.weapon.blade.id != 0) return 1;
    }
    return 0;
}
