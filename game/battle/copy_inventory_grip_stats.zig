//! Copies an inventory grip's stats into a battle UI equipment record (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: vs_battle_copyInventoryGripStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the id, sub id, category, gem slots, stats, index and item types of an inventory grip into a UI equipment record.
pub fn copyInventoryGripStats(target: ?*v.vs_battle_uiEquipment, source: ?*v.vs_main_inventoryGrip) callconv(.c) void {
    const dst = target.?;
    const src = source.?;

    dst.id = src.id;
    dst.subId = psx.conv(i8, src.subId);
    dst.category = src.category;
    dst.gemSlots = src.gemSlots;
    dst.strength = src.strength;
    dst.intelligence = src.intelligence;
    dst.agility = src.agility;
    dst.index = psx.conv(u8, src.index);

    for (0..4) |i| {
        dst.types[i] = src.types[i];
    }
}
