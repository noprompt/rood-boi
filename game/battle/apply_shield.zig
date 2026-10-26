//! Builds the shield intermediate from an inventory shield and applies it to the battle shield
//! (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_applyShield (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies an inventory shield (armor stats, material, gem stats) into a temporary and applies it to `target`.
pub fn applyShield(target: ?*v.vs_battle_uiShield, source: ?*v.vs_main_inventoryShield) callconv(.c) void {
    const raw = c.vs_main_allocHeapR(@sizeOf(v.vs_battle_shieldIntermediate));
    const tempShield: *v.vs_battle_shieldIntermediate = @ptrCast(@alignCast(raw.?));
    c.vs_main_bzero(raw, @sizeOf(v.vs_battle_shieldIntermediate));

    if (source) |src| {
        tempShield.index = psx.conv(i16, src.index);

        c.vs_battle_copyInventoryArmorStats(@ptrCast(&tempShield.base), psx.cptr(c.vs_main_inventoryArmor, &src.base));

        tempShield.material = psx.conv(u8, src.base.material);

        for (0..3) |i| {
            if (src.gems[i] != 0) {
                // (gem & 0x7F) - 1: a gem byte of 0x80 gives -1, which the C indexes without a check.
                const idx: c_int = (@as(c_int, src.gems[i]) & 0x7F) -% 1;
                c.vs_battle_copyInventoryGemStats(
                    @ptrCast(&tempShield.gems[i]),
                    psx.cptr(c.vs_main_inventoryGem, psx.at(&v.g.vs_main_inventory().gems, idx)),
                );
            }
        }
    }

    c.vs_battle_applyShieldStats(@ptrCast(target), @ptrCast(tempShield));
    c.vs_main_freeHeapR(raw);
}
