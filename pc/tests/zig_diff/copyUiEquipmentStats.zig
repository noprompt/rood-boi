//! zig_diff spec: vs_battle_copyUiEquipmentStats -> copy_ui_equipment_stats.copyUiEquipmentStats (146C.c).
//! Inputs: a target armor and a UI equipment block, both in the arena, with
//! random bytes everywhere. The C has no calls, no globals and no null test,
//! so both pointers are always valid. The source's id, subId and array
//! elements take edge values (ids with bit 7 and bit 8 set, the signed
//! extremes), so the u16 to u8 narrowing of `id` and each copied byte are
//! checked. Two classes split on whether `id` fits a byte.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").copyUiEquipmentStats));

pub const classes = [_][:0]const u8{ "id-fits", "id-truncated" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_main_inventoryArmor);
    const source = ctx.alloc(v.vs_battle_uiEquipment);

    source.id = ctx.pick(u16, &.{ 0, 1, 127, 128, 255, 256, 0x7FFF, 0xFFFF });
    source.subId = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.wepId = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.category = ctx.pick(u8, &.{ 0, 127, 128, 255 });
    source.currentDp = ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF });
    source.maxDp = ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF });
    source.currentPp = ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF });
    source.maxPp = ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF });
    source.gemSlots = ctx.pick(u8, &.{ 0, 127, 128, 255 });
    source.strength = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.intelligence = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.agility = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    for (&source.types) |*t| t.* = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    for (&source.classes) |*t| t.* = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    for (&source.affinities) |*t| t.* = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.material = ctx.pick(u8, &.{ 0, 127, 128, 255 });

    return .{ target, source };
}

pub fn classify(args: Args) usize {
    return if (args[1].?.id > 255) 1 else 0;
}
