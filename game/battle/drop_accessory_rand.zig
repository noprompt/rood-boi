//! Rolls whether a looted accessory drops and, on a drop, copies its stats into the loot (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _dropAccessoryRand (src/BATTLE/BATTLE.PRG/146C.c)
/// Rolls a 0..255 draw against the accessory's drop rate; on a drop copies its stats into the loot and returns 1, else 0.
pub fn dropAccessoryRand(looted: ?*v.vs_battle_lootedAccessory, base: ?*v.vs_battle_uiAccessory) callconv(.c) c_int {
    if (c.vs_main_getRand(0xFF) < @as(c_int, base.?.dropRate)) {
        const l = looted.?;
        const b = base.?;
        c.vs_battle_copyUiEquipmentStats(psx.cptr(c.vs_main_inventoryArmor, &l.accessory), @ptrCast(&b.accessory));

        l.difficultyFlags = 3;
        return 1;
    }

    return 0;
}
