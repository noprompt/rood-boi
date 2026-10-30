//! Health band of an equipment-screen limb (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: vs_battle_getLimbStatus (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Classifies a limb's HP as critical, damaged, wounded, good or excellent.
pub fn getLimbStatus(limb: ?*v.vs_battle_uiEquipment_limb) callconv(.c) c_int {
    const l = limb.?;
    const maxHp: c_int = l.maxHp;
    const hp: c_int = l.hp;

    if (hp < 2) {
        return c.limbStatusCritical;
    }

    if (hp *% 4 < maxHp) {
        return c.limbStatusDamaged;
    }

    if (hp *% 4 < maxHp *% 3) {
        return c.limbStatusWounded;
    }

    if (hp < maxHp) {
        return c.limbStatusGood;
    }

    return c.limbStatusExcellent;
}
