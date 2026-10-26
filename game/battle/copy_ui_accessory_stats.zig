//! Copies an accessory's equipment stats into an inventory armor slot (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_copyUiAccessoryStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the accessory's equipment stats into `target` when the accessory is present (id != 0).
pub fn copyUiAccessoryStats(target: ?*v.vs_main_inventoryArmor, source: ?*v.vs_battle_uiAccessory) callconv(.c) void {
    const s = source.?;
    if (s.accessory.id != 0) {
        c.vs_battle_copyUiEquipmentStats(@ptrCast(target), @ptrCast(&s.accessory));
    }
}
