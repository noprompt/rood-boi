//! Whether the water defense-up effect can apply to a target: it must pass the
//! effect check and wear armor on a limb or carry a shield (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyWaterDefenseUp (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the effect check passes and the target has any limb armor or a shield, else 0.
pub fn hitPrerequisiteCanApplyWaterDefenseUp(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    if (c._hitPrerequisiteCanApplyEffect(28, arg1) == 0) {
        var hasArmor: c_int = 0;
        const actor = psx.get(v.g.vs_battle_actors()[arg1[0]].?.stats).?;

        for (0..6) |i| {
            if (actor.limbs[i].armor.armor.id != 0) {
                hasArmor = 1;
            }
        }

        if (actor.shield.base.id != 0) {
            hasArmor = 1;
        }

        if (hasArmor != 0) {
            return 1;
        }
    }
    return 0;
}
