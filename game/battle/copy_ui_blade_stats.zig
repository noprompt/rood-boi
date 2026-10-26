//! Copies a battle inventory blade's stats from a UI equipment record (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: vs_battle_copyUiBladeStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies an equipment's stats into a blade, masking the damage and cost types to their bitfield widths.
pub fn copyUiBladeStats(target: ?*v.vs_main_inventoryBlade, source: ?*v.vs_battle_uiEquipment) callconv(.c) void {
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
    t.strength = s.strength;
    t.intelligence = s.intelligence;
    t.agility = s.agility;
    t.cost = s.cost;
    psx.setBits(t, "damageType", psx.conv(u2, @as(c_int, s.damageType) & 3));
    psx.setBits(t, "costType", psx.conv(u3, @as(c_int, s.costType) & 7));
    t.unk12 = psx.conv(u16, s.unk14);
    t.range = s.range;

    // The C goes through tempBlade, which is target itself.
    for (0..6) |i| {
        t.classes[i] = s.classes[i];
    }

    for (0..7) |i| {
        t.affinities[i] = s.affinities[i];
    }

    t.material = psx.conv(u16, s.material);
}
