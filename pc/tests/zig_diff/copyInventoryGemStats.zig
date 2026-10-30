//! zig_diff spec: vs_battle_copyInventoryGemStats -> copy_inventory_gem_stats.copyInventoryGemStats (146C.c).
//! Inputs: a source gem and a target block, each in its own arena object, with
//! every byte random so the signed and unsigned fields take negative and high
//! values. gemEffects and subId are biased toward values with and without the
//! top bit, and index toward both signs and the i16 edges. The copy makes no
//! calls and has no branches except its two loops, which always run to their
//! exit (6 and 7), so every loop comparison sees equal sides.

const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").copyInventoryGemStats));

pub const classes = [_][:0]const u8{ "index-negative", "index-non-negative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_battle_uiEquipment);
    const source = ctx.alloc(v.vs_main_inventoryGem);
    source.index = ctx.pick(i16, &.{ 0, 1, -1, 255, 256, 32767, -32768 });
    source.gemEffects = ctx.pick(u8, &.{ 0, 0x7F, 0x80, 0xFF });
    source.subId = ctx.pick(u8, &.{ 0, 0x7F, 0x80, 0xFF });
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    return if (args[1].?.index < 0) 0 else 1;
}
