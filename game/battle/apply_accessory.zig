//! Applies a worn accessory to the battle UI accessory (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_applyAccessory (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies an inventory armor's index and stats into a temporary accessory and applies it to the UI accessory.
pub fn applyAccessory(target: ?*v.vs_battle_uiAccessory, source: ?*v.vs_main_inventoryArmor) callconv(.c) void {
    const temp: *v._accessoryIntermediate = @ptrCast(@alignCast(c.vs_main_allocHeapR(@as(c_uint, @sizeOf(v._accessoryIntermediate))).?));
    c.vs_main_bzero(temp, @as(c_int, @sizeOf(v._accessoryIntermediate)));

    if (source) |s| {
        temp.index = s.index;
        c.vs_battle_copyInventoryArmorStats(@ptrCast(&temp.equip), psx.cptr(c.vs_main_inventoryArmor, s));
    }

    c._applyAccessoryStats(@ptrCast(target), @ptrCast(temp));
    c.vs_main_freeHeapR(temp);
}
