//! zig_diff spec: vs_battle_copyInventoryBladeStats -> copy_inventory_blade_stats.copyInventoryBladeStats (146C.c).
//! Inputs: a target and a source, both in the arena and both non-null (the C
//! never tests them). The source keeps the harness's random bytes, so every
//! copied field sees arbitrary values, including the bitfields damageType and
//! costType and the signed i8 stats. Some inputs are biased toward edges
//! (i8 minimum and -1, u16 extremes). Classes split on the sign of strength.
//! The target's untouched bytes (affinities[7], range, types, gem fields)
//! keep their random fill, so the state comparison also checks what the C
//! leaves alone. The C makes no calls and has only the two constant loops.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").copyInventoryBladeStats));

pub const classes = [_][:0]const u8{ "non-negative-strength", "negative-strength" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_battle_uiEquipment);
    const source = ctx.alloc(v.vs_main_inventoryBlade);
    if (ctx.chance(3)) {
        source.strength = ctx.pick(i8, &.{ -128, -1, 0, 127 });
        source.intelligence = ctx.pick(i8, &.{ -128, -1, 0, 127 });
        source.agility = ctx.pick(i8, &.{ -128, -1, 0, 127 });
        source.cost = ctx.pick(u8, &.{ 0, 255 });
        source.maxDp = ctx.pick(u16, &.{ 0, 0xFFFF });
        source.currentDp = ctx.pick(u16, &.{ 0, 0x8000, 0xFFFF });
        source.unk12 = ctx.pick(u16, &.{ 0, 0x8000, 0xFFFF });
    }
    psx.setBits(source, "damageType", ctx.int(u2));
    psx.setBits(source, "costType", ctx.int(u3));
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    const source = args[1].?;
    return if (source.strength < 0) 1 else 0;
}
