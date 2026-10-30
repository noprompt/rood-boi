//! Air defense up prerequisite: whether the actor in a slot wears any armor or a shield (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyAirDefenseUp (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the effect check passes for the actor in slot `arg1` and it wears armor or a shield, else 0.
pub fn hitPrerequisiteCanApplyAirDefenseUp(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    if (c._hitPrerequisiteCanApplyEffect(25, arg1) == 0) {
        var hasArmor = false;
        const actor = psx.get(v.g.vs_battle_actors()[arg1[0]].?.stats).?;

        for (&actor.limbs) |*limb| {
            if (limb.armor.armor.id != 0) {
                hasArmor = true;
            }
        }

        if (actor.shield.base.id != 0) {
            hasArmor = true;
        }

        if (hasArmor) {
            return 1;
        }
    }
    return 0;
}
