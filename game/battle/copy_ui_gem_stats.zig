//! Copies a UI equipment entry's gem fields into an inventory gem record (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: vs_battle_copyUiGemStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies a gem's identity, stats, classes and affinities from a UI equipment entry.
pub fn copyUiGemStats(target: ?*v.vs_main_inventoryGem, source: ?*v.vs_battle_uiEquipment) callconv(.c) void {
    const dst = target.?;
    const src = source.?;

    dst.id = src.id;
    dst.subId = psx.conv(u8, src.subId);
    dst.gemEffects = src.gemEffects;
    dst.strength = src.strength;
    dst.intelligence = src.intelligence;
    dst.agility = src.agility;

    for (0..6) |i| {
        dst.classes[i] = src.classes[i];
    }

    for (0..7) |i| {
        dst.affinities[i] = src.affinities[i];
    }
}
