//! zig_diff spec: vs_battle_copyInventoryArmorStats -> copy_inventory_armor_stats.copyInventoryArmorStats (146C.c).
//! Inputs: a source inventory armor and a target UI equipment, both in the arena
//! with random bytes, so every copied field differs from the target's old value.
//! Source material, maxDp and strength are biased to edge values: material's high
//! byte is the case the u8 target truncates. The C makes no calls; its only
//! branches are the four copy loops.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").copyInventoryArmorStats));

pub const classes = [_][:0]const u8{ "material-high-byte", "material-low-byte" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_battle_uiEquipment);
    const source = ctx.alloc(v.vs_main_inventoryArmor);
    source.material = ctx.pick(u16, &.{ 0, 0xFF, 0x100, 0xFFFF });
    source.maxDp = ctx.pick(u16, &.{ 0, 1, 0xFFFF, 0x8000 });
    source.strength = ctx.pick(i8, &.{ 0, -1, 127, -128 });
    source.agility = ctx.pick(i8, &.{ 0, -1, 127, -128 });
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    return if (args[1].?.material > 0xFF) 0 else 1;
}
