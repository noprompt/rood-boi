//! Copies an inventory armor entry into a battle equipment record
//! (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: vs_battle_copyInventoryArmorStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies an armor's stats, types, classes, affinities and material into an equipment record.
pub fn copyInventoryArmorStats(target: ?*v.vs_battle_uiEquipment, source: ?*v.vs_main_inventoryArmor) callconv(.c) void {
    const dst = target.?;
    const src = source.?;

    dst.id = psx.conv(u16, src.id);
    dst.subId = psx.conv(i8, src.subId);
    dst.wepId = psx.conv(i8, src.wepId);
    dst.category = src.category;
    dst.currentDp = src.currentDp;
    dst.maxDp = src.maxDp;
    dst.currentPp = src.currentPp;
    dst.maxPp = src.maxPp;
    dst.gemSlots = src.gemSlots;
    dst.strength = src.strength;
    dst.intelligence = src.intelligence;
    dst.agility = src.agility;
    dst.index = src.index;

    for (0..4) |i| {
        dst.types[i] = src.types[i];
    }

    // The C copies six of the eight classes.
    for (0..6) |i| {
        dst.classes[i] = src.classes[i];
    }

    // The C copies seven of the eight affinities.
    for (0..7) |i| {
        dst.affinities[i] = src.affinities[i];
    }

    dst.material = psx.conv(u8, src.material);
}
