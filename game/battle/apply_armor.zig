//! Applies a worn armor piece's stats to the battle armor UI record (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_applyArmor (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies a worn armor piece (nothing, when source is null) into an intermediate record and applies it to target.
pub fn applyArmor(target: ?*v.vs_battle_uiArmor, source: ?*v.vs_main_inventoryArmor) callconv(.c) void {
    const raw = c.vs_main_allocHeapR(@as(c_uint, @sizeOf(v._armorIntermediate)));
    const temp: *v._armorIntermediate = @ptrCast(@alignCast(raw.?));
    c.vs_main_bzero(raw, @as(c_int, @sizeOf(v._armorIntermediate)));

    if (source) |src| {
        temp.index = src.index;

        c.vs_battle_copyInventoryArmorStats(@ptrCast(&temp.equip), psx.cptr(c.vs_main_inventoryArmor, src));

        temp.material = psx.conv(u8, src.material);
    }

    c._applyArmorStats(@ptrCast(target), @ptrCast(temp));
    c.vs_main_freeHeapR(raw);
}
