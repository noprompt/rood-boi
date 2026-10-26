//! Copies an armor's current DP into its equipment record and copies the equipment stats to the inventory armor (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_copyUiArmorStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies a battle armor's stats into the inventory armor `target`, when the armor slot holds an item.
pub fn copyUiArmorStats(target: ?*v.vs_main_inventoryArmor, source: ?*v.vs_battle_uiArmor) callconv(.c) void {
    const s = source.?;
    if (s.armor.id != 0) {
        s.armor.currentDp = s.currentDp;
        c.vs_battle_copyUiEquipmentStats(@ptrCast(target), @ptrCast(&s.armor));
    }
}
