//! Copies an inventory blade's stats into a battle equipment record (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: vs_battle_copyInventoryBladeStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the stats, class and affinity bytes and material of an inventory blade into a battle equipment record.
pub fn copyInventoryBladeStats(target: ?*v.vs_battle_uiEquipment, source: ?*v.vs_main_inventoryBlade) callconv(.c) void {
    const t = target.?;
    const s = source.?;

    t.id = psx.conv(u16, s.id);
    t.subId = psx.conv(i8, s.subId);
    t.wepId = psx.conv(i8, s.wepId);
    t.category = s.category;
    t.currentDp = s.currentDp;
    t.maxDp = s.maxDp;
    t.currentPp = s.currentPp;
    t.maxPp = s.maxPp;
    t.strength = s.strength;
    t.intelligence = s.intelligence;
    t.agility = s.agility;
    t.cost = s.cost;
    t.damageType = psx.conv(u8, psx.getBits(s, "damageType"));
    t.costType = psx.conv(u8, psx.getBits(s, "costType"));
    t.unk14 = psx.conv(u8, s.unk12);
    t.range = s.range;
    t.index = s.index;

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        t.classes[i] = s.classes[i];
    }

    i = 0;
    while (i < 7) : (i += 1) {
        t.affinities[i] = s.affinities[i];
    }

    t.material = psx.conv(u8, s.material);
}
