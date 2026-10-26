//! Rolls whether a looted armor piece drops and places it in the first free loot slot (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _dropArmorRand (src/BATTLE/BATTLE.PRG/146C.c)
/// Rolls against the armor's drop rate and, on success, copies it into the first free of two loot slots.
pub fn dropArmorRand(looted: ?*v.vs_battle_lootedArmor, base: ?*v.vs_battle_uiArmor) callconv(.c) c_int {
    const roll = c.vs_main_getRand(0xFF);
    if (roll < @as(c_int, base.?.dropRate)) {
        var i: c_int = 0;
        while (i < 2) : (i += 1) {
            const slot = psx.at(looted.?, i);
            if (slot.armor.id == 0) {
                c.vs_battle_copyUiEquipmentStats(
                    psx.cptr(c.vs_main_inventoryArmor, &slot.armor),
                    @ptrCast(&base.?.armor),
                );

                slot.difficultyFlags = 3;
                return 1;
            }
        }
    }

    return 0;
}
