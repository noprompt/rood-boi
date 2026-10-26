//! zig_diff spec: vs_battle_copyUiArmorStats -> copy_ui_armor_stats.copyUiArmorStats (146C.c).
//! Inputs: a uiArmor in the arena whose armor id is 0 (the skipped case), a
//! nonzero id with the sign bit set, or a nonzero id without it (edges 1,
//! 0x7FFF, 0x8000, 0xFFFF plus random values), random currentDp and maxDp
//! (the stored field differs from the one the store reads), and a target that
//! is sometimes null (the C never tests it; the callee stub does not touch it).
//! The callee is a recording stub that writes the target and sometimes the
//! equipment's currentDp, so a port that stores after the call, or skips the
//! store, changes the state seen at the call or after it.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").copyUiArmorStats));

pub const classes = [_][:0]const u8{ "no-armor", "armor-sign-bit", "armor-plain-id" };

pub const stubs = struct {
    pub fn vs_battle_copyUiEquipmentStats(ctx: *zd.Ctx, target: anytype, equipment: anytype) void {
        const e: *v.vs_battle_uiEquipment = @ptrCast(@alignCast(equipment));
        if (ctx.value(u1) == 1) e.currentDp = ctx.value(u16);
        if (target == null) return;
        const t: *v.vs_main_inventoryArmor = @ptrCast(@alignCast(target));
        t.currentDp = ctx.value(u16);
        t.maxDp = ctx.value(u16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const source = ctx.alloc(v.vs_battle_uiArmor);
    const target: ?*v.vs_main_inventoryArmor = if (ctx.chance(8)) null else ctx.alloc(v.vs_main_inventoryArmor);
    source.armor.id = ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF });
    source.currentDp = ctx.int(u16);
    source.maxDp = ctx.int(u16);
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    const id = args[1].?.armor.id;
    if (id == 0) return 0;
    return if ((id & 0x8000) != 0) 1 else 2;
}
