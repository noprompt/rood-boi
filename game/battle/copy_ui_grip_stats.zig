//! Copies a UI equipment record's grip stats into an inventory grip (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const psx = @import("common").psx;

/// orig: vs_battle_copyUiGripStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the identity, stat and type fields of a UI equipment record into an inventory grip.
pub fn copyUiGripStats(target: ?*v.vs_main_inventoryGrip, source: ?*v.vs_battle_uiEquipment) callconv(.c) void {
    const dst = target.?;
    const src = source.?;

    dst.id = src.id;
    dst.subId = psx.conv(u8, src.subId);
    dst.category = src.category;
    dst.gemSlots = src.gemSlots;
    dst.strength = src.strength;
    dst.intelligence = src.intelligence;
    dst.agility = src.agility;

    var i: usize = 0;
    while (i < 4) : (i += 1) {
        dst.types[i] = src.types[i];
    }
}
