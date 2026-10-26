//! Armor stats: copies an equipment intermediate into the battle armor record (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _applyArmorStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Fills a battle armor record from an equipment intermediate: equipment copy, stats, types, class and affinity tables, drop rate.
pub fn applyArmorStats(target: ?*v.vs_battle_uiArmor, source: ?*v._armorIntermediate) callconv(.c) void {
    const t = target.?;
    const s = source.?;

    c.vs_main_memcpy(&t.armor, &s.equip, @sizeOf(v.vs_battle_uiEquipment));

    t.armor.material = s.material;
    t.currentDp = s.equip.currentDp;
    t.maxDp = s.equip.maxDp;
    // currentStr = baseStr = strength: the round trip through u16 gives the same value as converting from the i8 directly.
    t.currentStr = psx.conv(i16, s.equip.strength);
    t.baseStr = psx.conv(u16, s.equip.strength);
    t.currentInt = psx.conv(i16, s.equip.intelligence);
    t.baseInt = psx.conv(u16, s.equip.intelligence);
    t.currentAgility = psx.conv(i16, s.equip.agility);
    t.baseAgility = psx.conv(u16, s.equip.agility);
    t.index = s.index;

    for (0..4) |i| {
        t.types[i] = psx.conv(u16, s.equip.types[i]);
    }

    for (0..6) |i| {
        const cv = psx.conv(i16, s.equip.classes[i]);
        t.classAffinityCurrent.class[1][i] = cv;
        t.classAffinityCurrent.class[0][i] = cv;
        t.classAffinityBaseline.class[i] = cv;
    }

    for (0..7) |i| {
        const av = s.equip.affinities[i];
        t.unk88[i] = 0;
        t.classAffinityCurrent.affinity[1][i] = psx.conv(i16, av);
        t.classAffinityCurrent.affinity[0][i] = psx.conv(i16, av);
        t.classAffinityBaseline.affinity[i] = psx.conv(u16, av);
    }

    t.dropRate = s.dropRate;
    t.unk99 = s.unk32;
}
