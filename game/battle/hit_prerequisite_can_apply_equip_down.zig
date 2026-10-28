//! Prerequisite for the equipment-down hit effect: true when the target has any armor, shield or weapon equipped (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyEquipDown (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the target of the hit (`arg1`, an actor slot) has any limb armor, shield or weapon equipped, else 0.
pub fn hitPrerequisiteCanApplyEquipDown(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    if (c._hitPrerequisiteCanApplyEffect(19, arg1) != 0) {
        return 0;
    }

    var hasEquipment: c_int = 0;
    const actor = psx.get(v.g.vs_battle_actors()[arg1[0]].?.stats).?;

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        if (actor.limbs[i].armor.armor.id != 0) {
            hasEquipment = 1;
        }
    }

    if (actor.shield.base.id != 0) {
        hasEquipment = 1;
    }

    if (actor.weapon.blade.id != 0) {
        hasEquipment = 1;
    }

    if (hasEquipment != 0) {
        return 1;
    }

    return 0;
}
