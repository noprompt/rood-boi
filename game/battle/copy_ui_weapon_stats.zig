//! Copies a UI weapon's blade, grip, gems and name back into the inventory
//! slots its target weapon points at (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_copyUiWeaponStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Writes a UI weapon's parts and name into the inventory, when its blade is present.
pub fn copyUiWeaponStats(target: ?*v.vs_main_inventoryWeapon, source: ?*v.vs_battle_uiWeapon) callconv(.c) void {
    const s = source.?;

    if (s.blade.id != 0) {
        // The target is only dereferenced here, as in the C (it may be null when the blade is empty).
        const t = target.?;
        const inv = v.g.vs_main_inventory();

        s.blade.currentDp = s.currentDp;
        s.blade.currentPp = s.currentPp;

        // Slot indices are the 1-based ids minus one; the C does not check them.
        c.vs_battle_copyUiBladeStats(
            @ptrCast(psx.at(&inv.blades, @as(c_int, t.blade) - 1)),
            @ptrCast(&s.blade),
        );
        c.vs_battle_copyUiGripStats(
            psx.cptr(c.vs_main_inventoryGrip, psx.at(&inv.grips, @as(c_int, t.grip) - 1)),
            @ptrCast(&s.grip),
        );

        // i runs over the three gem slots only.
        var i: usize = 0;
        while (i < 3) : (i += 1) {
            if (s.gems[i].id != 0) {
                c.vs_battle_copyUiGemStats(
                    psx.cptr(c.vs_main_inventoryGem, psx.at(&inv.gems, @as(c_int, t.gems[i]) - 1)),
                    @ptrCast(&s.gems[i]),
                );
            }
        }

        // Both names are 24 bytes.
        var n: usize = 0;
        while (n < 24) : (n += 1) {
            t.name[n] = s.name[n];
        }
    }
}
