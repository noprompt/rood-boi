//! zig_diff spec: vs_battle_copyInventoryGripStats -> copy_inventory_grip_stats.copyInventoryGripStats (146C.c).
//! Inputs: a fresh target and source in the arena, every field of the source random
//! (the arena fill), with the id, index and assembledWeaponIndex drawn from edges that
//! carry the sign bit and the u8/u16 truncation points. The C has no calls and no null
//! tests, so both pointers are always valid. The source's index (u16) is stored into the
//! target's index (u8), so the high byte is dropped; the target's untouched fields keep
//! their random bytes and are compared too.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").copyInventoryGripStats));

pub const classes = [_][:0]const u8{ "source-id-sign-bit", "source-id-no-sign-bit" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_battle_uiEquipment);
    const source = ctx.alloc(v.vs_main_inventoryGrip);
    source.id = ctx.pick(u16, &.{ 0, 0x7FFF, 0x8000, 0xFFFF });
    source.index = ctx.pick(u16, &.{ 0, 0xFF, 0x100, 0xFFFF });
    source.assembledWeaponIndex = ctx.pick(u16, &.{ 0, 0xFF, 0x100, 0xFFFF });
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    const source = args[1].?;
    return if ((source.id & 0x8000) != 0) 0 else 1;
}
