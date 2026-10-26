//! Rolls a dropped weapon: when the drop roll succeeds, copies the base weapon's stats into the loot (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _dropWeaponRand (src/BATTLE/BATTLE.PRG/146C.c)
/// Rolls the weapon's drop rate and, on a drop, copies its blade, grip, gems and name into the loot.
pub fn dropWeaponRand(looted: ?*v.vs_battle_lootedWeapon, base: ?*v.vs_battle_uiWeapon) callconv(.c) c_int {
    if (c.vs_main_getRand(0xFF) < @as(c_int, base.?.dropRate)) {
        const loot = looted.?;
        const weapon = base.?;

        c.vs_battle_copyUiBladeStats(@ptrCast(&loot.blade), @ptrCast(&weapon.blade));
        c.vs_battle_copyUiGripStats(psx.cptr(c.vs_main_inventoryGrip, &loot.grip), @ptrCast(&weapon.grip));

        var i: usize = 0;
        while (i < 3) : (i += 1) {
            if (weapon.gems[i].id != 0) {
                c.vs_battle_copyUiGemStats(psx.cptr(c.vs_main_inventoryGem, &loot.gems[i]), @ptrCast(&weapon.gems[i]));
            }
        }

        c.vs_main_memcpy(&loot.name, &weapon.name, 24);

        loot.difficultyFlags = 3;

        return 1;
    }

    return 0;
}
