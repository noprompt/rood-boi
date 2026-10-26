//! Fills a UI accessory record from an accessory intermediate: the equipment copy, current stats, drop rate, index and widened per-slot tables (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _applyAccessoryStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies an accessory's equipment into a UI accessory and widens its types, classes and affinities to 16 bits.
pub fn applyAccessoryStats(target: ?*v.vs_battle_uiAccessory, source: ?*v._accessoryIntermediate) callconv(.c) void {
    const t = target.?;
    const s = source.?;

    c.vs_main_memcpy(t, &s.equip, @as(c_uint, @sizeOf(v.vs_battle_uiEquipment)));

    t.currentStr = psx.conv(i16, s.equip.strength);
    t.currentInt = psx.conv(i16, s.equip.intelligence);
    t.currentAgility = psx.conv(i16, s.equip.agility);
    t.dropRate = s.dropRate;
    t.index = s.index;

    for (0..4) |i| {
        t.types[i] = psx.conv(u16, s.equip.types[i]);
    }

    for (0..6) |i| {
        t.classes[i] = psx.conv(u16, s.equip.classes[i]);
    }

    for (0..7) |i| {
        t.affinities[i] = psx.conv(u16, s.equip.affinities[i]);
    }
}
