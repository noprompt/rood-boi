//! Rolls a looted shield's drop; on a drop copies the shield and its gems into the loot (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _dropShieldRand (src/BATTLE/BATTLE.PRG/146C.c)
/// Rolls the shield's drop rate; on a drop copies its stats and gems into the loot and returns 1, else 0.
pub fn dropShieldRand(looted: ?*v.vs_battle_lootedShield, base: ?*v.vs_battle_uiShield) callconv(.c) c_int {
    if (c.vs_main_getRand(0xFF) < @as(c_int, base.?.dropRate)) {
        const l = looted.?;
        const b = base.?;
        c.vs_battle_copyUiEquipmentStats(psx.cptr(c.vs_main_inventoryArmor, &l.shield), @ptrCast(&b.base));

        var i: usize = 0;
        while (i < 3) : (i += 1) {
            if (b.gems[i].id != 0) {
                c.vs_battle_copyUiGemStats(psx.cptr(c.vs_main_inventoryGem, &l.gems[i]), @ptrCast(&b.gems[i]));
            }
        }

        l.difficultyFlags = 3;
        return 1;
    }

    return 0;
}
