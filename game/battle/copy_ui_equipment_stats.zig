//! Copies an equipment entry's stats, types, classes and affinities into an inventory armor record (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: vs_battle_copyUiEquipmentStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies a UI equipment entry's stats and its type, class and affinity arrays into an inventory armor record.
pub fn copyUiEquipmentStats(target: ?*v.vs_main_inventoryArmor, source: ?*v.vs_battle_uiEquipment) callconv(.c) void {
    const t = target.?;
    const s = source.?;

    t.id = psx.conv(u8, s.id);
    t.subId = psx.conv(u8, s.subId);
    t.wepId = psx.conv(u8, s.wepId);
    t.category = s.category;
    t.currentDp = s.currentDp;
    t.maxDp = s.maxDp;
    t.currentPp = s.currentPp;
    t.maxPp = s.maxPp;
    t.gemSlots = s.gemSlots;
    t.strength = s.strength;
    t.intelligence = s.intelligence;
    t.agility = s.agility;

    for (0..4) |i| {
        t.types[i] = s.types[i];
    }
    for (0..6) |i| {
        t.classes[i] = s.classes[i];
    }
    for (0..7) |i| {
        t.affinities[i] = s.affinities[i];
    }

    t.material = psx.conv(u16, s.material);
}
