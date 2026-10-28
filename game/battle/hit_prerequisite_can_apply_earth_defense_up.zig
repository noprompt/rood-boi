//! Earth Defense Up's prerequisite: the target has armor or a shield to defend with (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyEarthDefenseUp (src/BATTLE/BATTLE.PRG/146C.c)
/// Whether Earth Defense Up can apply to the actor in slot `arg1`: the effect check passes and it wears armor or a shield.
pub fn hitPrerequisiteCanApplyEarthDefenseUp(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    if (c._hitPrerequisiteCanApplyEffect(27, arg1) != 0) return 0;

    var hasArmor = false;
    const owner: *v.vs_battle_actor = psx.at(v.g.vs_battle_actors(), arg1[0]).*.?;
    const actor: *v.vs_battle_actor2 = psx.get(owner.stats).?;

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        if (actor.limbs[i].armor.armor.id != 0) {
            hasArmor = true;
        }
    }

    if (actor.shield.base.id != 0) {
        hasArmor = true;
    }
    return if (hasArmor) 1 else 0;
}
