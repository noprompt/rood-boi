//! Copies a shield's stats into its inventory entry and the gems it holds
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_copyUiShieldStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies an equipped shield's UI stats into its inventory entry, then each socketed gem's stats.
pub fn copyUiShieldStats(target: ?*v.vs_main_inventoryShield, source: ?*v.vs_battle_uiShield) callconv(.c) void {
    const src = source.?;
    if (src.base.id == 0) return;

    src.base.currentDp = src.currentDp;
    src.base.currentPp = src.currentPp;

    // &target->base: the address alone, so a null target gives offsetof(base) as the C does.
    const armor: [*c]c.vs_main_inventoryArmor = if (target) |t|
        psx.cptr(c.vs_main_inventoryArmor, &t.base)
    else
        @ptrFromInt(@offsetOf(v.vs_main_inventoryShield, "base"));
    const equipment: ?*c.vs_battle_uiEquipment = @ptrCast(&src.base);
    c.vs_battle_copyUiEquipmentStats(armor, equipment);

    var i: usize = 0;
    while (i < 3) : (i += 1) {
        if (src.gems[i].id != 0) {
            // target->gems[i] - 1 is C int arithmetic: index -1 is possible and is not checked.
            const t = target.?;
            const idx: c_int = @as(c_int, t.gems[i]) - 1;
            c.vs_battle_copyUiGemStats(
                psx.cptr(c.vs_main_inventoryGem, psx.at(&v.g.vs_main_inventory().gems, idx)),
                @ptrCast(&src.gems[i]),
            );
        }
    }
}
