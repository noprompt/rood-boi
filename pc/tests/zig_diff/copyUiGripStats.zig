//! zig_diff spec: vs_battle_copyUiGripStats -> copy_ui_grip_stats.copyUiGripStats (146C.c).
//! Inputs: a fresh inventoryGrip target whose bytes are random, and a uiEquipment
//! source whose fields are biased to the edges (0, -1, 127, -128, the unsigned
//! extremes), so every copied byte is checked for signed and unsigned reads.
//! The C makes no calls and has no tests beyond the four-step types loop. The
//! classes split on the sign of the source's subId.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").copyUiGripStats));

pub const classes = [_][:0]const u8{ "subId-negative", "subId-non-negative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_main_inventoryGrip);
    const source = ctx.alloc(v.vs_battle_uiEquipment);

    source.id = ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF });
    source.subId = ctx.pick(i8, &.{ 0, -1, 127, -128 });
    source.category = ctx.pick(u8, &.{ 0, 1, 127, 128, 255 });
    source.gemSlots = ctx.pick(u8, &.{ 0, 1, 127, 128, 255 });
    source.strength = ctx.pick(i8, &.{ 0, -1, 127, -128 });
    source.intelligence = ctx.pick(i8, &.{ 0, -1, 127, -128 });
    source.agility = ctx.pick(i8, &.{ 0, -1, 127, -128 });
    for (&source.types) |*t| t.* = ctx.pick(i8, &.{ 0, -1, 127, -128 });

    return .{ target, source };
}

pub fn classify(args: Args) usize {
    const source = args[1].?;
    return if (source.subId < 0) 0 else 1;
}
