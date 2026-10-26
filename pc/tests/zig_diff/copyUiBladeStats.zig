//! zig_diff spec: vs_battle_copyUiBladeStats -> copy_ui_blade_stats.copyUiBladeStats (146C.c).
//! Inputs: a random target blade and a random UI equipment record in the arena. Every
//! field is copied from random bytes with edge values mixed in: negative i8 stats,
//! 0 and 0xFFFF HP, and damageType/costType above and within their 2- and 3-bit masks.
//! Both pointers are always valid, since the C has no null test. The C calls nothing,
//! so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").copyUiBladeStats));

pub const classes = [_][:0]const u8{ "masked-bits", "in-mask-bits" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_main_inventoryBlade);
    const source = ctx.alloc(v.vs_battle_uiEquipment);

    source.id = ctx.pick(u16, &.{ 0, 1, 0xFFFF, 0x8000 });
    source.subId = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.wepId = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.strength = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.intelligence = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.agility = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.currentDp = ctx.pick(u16, &.{ 0, 1, 0xFFFF, 0x8000 });
    source.maxDp = ctx.pick(u16, &.{ 0, 1, 0xFFFF, 0x8000 });
    source.currentPp = ctx.pick(u16, &.{ 0, 1, 0xFFFF, 0x8000 });
    source.maxPp = ctx.pick(u16, &.{ 0, 1, 0xFFFF, 0x8000 });
    // The bitfield targets keep only 2 and 3 bits: values above the masks test the `& 3` and `& 7`.
    source.damageType = ctx.pick(u8, &.{ 0, 3, 4, 7, 255 });
    source.costType = ctx.pick(u8, &.{ 0, 7, 8, 255 });
    source.cost = ctx.pick(u8, &.{ 0, 1, 127, 255 });
    source.material = ctx.pick(u8, &.{ 0, 1, 127, 255 });
    source.unk14 = ctx.pick(u8, &.{ 0, 1, 127, 255 });
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    const source = args[1].?;
    return if (source.damageType > 3 or source.costType > 7) 0 else 1;
}
