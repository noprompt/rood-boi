//! Builds a battle weapon's intermediate stats from its inventory entry and applies them
//! to the target (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_applyWeapon (src/BATTLE/BATTLE.PRG/146C.c)
/// Gathers the blade, grip, gems and name of an inventory weapon and applies them to `target`.
pub fn applyWeapon(target: ?*v.vs_battle_uiWeapon, source: ?*v.vs_main_inventoryWeapon) callconv(.c) void {
    const inv = v.g.vs_main_inventory();
    const raw = c.vs_main_allocHeapR(@sizeOf(v.vs_battle_weaponIntermediate)).?;
    const temp: *v.vs_battle_weaponIntermediate = @ptrCast(@alignCast(raw));
    c.vs_main_bzero(temp, @sizeOf(v.vs_battle_weaponIntermediate));

    if (source) |src| {
        temp.index = src.index;

        if (src.blade != 0) {
            const bladeIdx = @as(c_int, src.blade) -% 1;
            c.vs_battle_copyInventoryBladeStats(@ptrCast(&temp.blade), @ptrCast(psx.at(&inv.blades, bladeIdx)));
            temp.material = psx.conv(u8, psx.at(&inv.blades, bladeIdx).material);
        }

        if (src.grip != 0) {
            c.vs_battle_copyInventoryGripStats(
                @ptrCast(&temp.grip),
                psx.cptr(c.vs_main_inventoryGrip, psx.at(&inv.grips, @as(c_int, src.grip) -% 1)),
            );
        }

        var i: usize = 0;
        while (i < 3) : (i += 1) {
            if (src.gems[i] != 0) {
                c.vs_battle_copyInventoryGemStats(
                    @ptrCast(&temp.gems[i]),
                    psx.cptr(c.vs_main_inventoryGem, psx.at(&inv.gems, @as(c_int, src.gems[i]) -% 1)),
                );
            }
        }

        temp.name = src.name;
    }

    c.vs_battle_applyWeaponStats(@ptrCast(target), @ptrCast(temp));
    c.vs_main_freeHeapR(temp);
}
