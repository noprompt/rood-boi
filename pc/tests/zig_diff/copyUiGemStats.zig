//! zig_diff spec: vs_battle_copyUiGemStats -> copy_ui_gem_stats.copyUiGemStats (146C.c).
//! Inputs: a target inventory gem and a source UI equipment, both in the arena
//! and both non-null (the C dereferences them). The source's id, gemEffects and
//! strength are drawn from edge values (0, 0xFFFF, sign-bit and extreme bytes)
//! half the time; the other fields keep the random fill. The two loops run to
//! 6 and 7, so their exits (i == 6, i == 7) are hit on every run, and the
//! target's bytes past the copied ones are compared as well.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").copyUiGemStats));

pub const classes = [_][:0]const u8{ "source-id-zero", "source-id-other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_main_inventoryGem);
    const source = ctx.alloc(v.vs_battle_uiEquipment);
    source.id = ctx.pick(u16, &.{ 0, 0xFFFF, 0x8000, 1 });
    source.gemEffects = ctx.pick(u8, &.{ 0, 0x80, 0xFF });
    source.strength = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.intelligence = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.agility = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    return if (args[1].?.id == 0) 0 else 1;
}
