//! Equipment check for the equip-up hit prerequisite (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyEquipUp (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the actor in slot `arg1` has armor, a shield or a weapon equipped, else 0.
pub fn hitPrerequisiteCanApplyEquipUp(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    if (c._hitPrerequisiteCanApplyEffect(20, arg1) != 0) {
        return 0;
    }

    var hasEquipment = false;
    const enemy = v.g.vs_battle_actors()[@as(usize, arg1[0])].?;
    const actor = psx.get(enemy.stats).?;

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        if (actor.limbs[i].armor.armor.id != 0) {
            hasEquipment = true;
        }
    }

    if (actor.shield.base.id != 0) {
        hasEquipment = true;
    }

    if (actor.weapon.blade.id != 0) {
        hasEquipment = true;
    }

    if (hasEquipment) {
        return 1;
    }

    return 0;
}
