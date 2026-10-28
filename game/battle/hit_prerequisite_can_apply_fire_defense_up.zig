//! Fire defense up's prerequisite: the target has some armor or a shield equipped
//! (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyFireDefenseUp (src/BATTLE/BATTLE.PRG/146C.c)
/// Fire defense up applies only when the effect itself can apply and the target wears armor or a shield.
pub fn hitPrerequisiteCanApplyFireDefenseUp(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    if (c._hitPrerequisiteCanApplyEffect(26, arg1) == 0) {
        var hasArmor: bool = false;
        const enemy = v.g.vs_battle_actors()[arg1[0]].?;
        const actor = psx.get(enemy.stats).?;

        var i: usize = 0;
        while (i < 6) : (i += 1) {
            if (actor.limbs[i].armor.armor.id != 0) {
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
