//! Copies a gem's stats into a battle equipment entry (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: vs_battle_copyInventoryGemStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies a gem's id, effects, stat bonuses, index, classes and affinities into an equipment entry.
pub fn copyInventoryGemStats(target: ?*v.vs_battle_uiEquipment, source: ?*v.vs_main_inventoryGem) callconv(.c) void {
    const t = target.?;
    const s = source.?;

    t.id = s.id;
    t.subId = @bitCast(s.subId);
    t.gemEffects = s.gemEffects;
    t.strength = s.strength;
    t.intelligence = s.intelligence;
    t.agility = s.agility;
    t.index = @truncate(@as(u16, @bitCast(s.index)));

    for (0..6) |i| {
        t.classes[i] = s.classes[i];
    }

    for (0..7) |i| {
        t.affinities[i] = s.affinities[i];
    }
}
