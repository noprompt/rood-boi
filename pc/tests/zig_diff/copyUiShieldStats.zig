//! zig_diff spec: vs_battle_copyUiShieldStats -> copy_ui_shield_stats.copyUiShieldStats (146C.c).
//! Inputs: a shield pair in the arena. The outer test is taken or not (the
//! source base id is zero, or a random id with and without the sign bit), and
//! each of the three gem slots is present or empty. The target's gem indices
//! cover 0 (index -1, into the armor array just before gems), the first slots
//! and the last gems, all inside vs_main_inventory. The two callees are
//! recording stubs that write back into the objects they receive, so a port
//! that reads a field before the call, or moves a store across it, differs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").copyUiShieldStats));

pub const classes = [_][:0]const u8{ "outer-off", "no-gems", "one-gem", "two-gems", "three-gems" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_main_inventoryShield);
    const source = ctx.alloc(v.vs_battle_uiShield);

    source.base.id = if (ctx.chance(5)) 0 else ctx.pick(u16, &.{ 1, 0x7FFF, 0x8000, 0xFFFF });
    for (&source.gems) |*g| {
        g.id = if (ctx.chance(2)) 0 else ctx.pick(u16, &.{ 1, 0x7FFF, 0x8000, 0xFFFF });
    }
    for (&target.gems) |*t| {
        t.* = ctx.edge(u8, &.{ 0, 1, 2, 3, 47, 48 });
    }
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    const source = args[1].?;
    if (source.base.id == 0) return 0;
    var n: usize = 0;
    for (source.gems) |g| {
        if (g.id != 0) n += 1;
    }
    return 1 + n;
}

fn asArmor(p: anytype) *v.vs_main_inventoryArmor {
    const o: ?*v.vs_main_inventoryArmor = @ptrCast(@alignCast(p));
    return o.?;
}

fn asEquipment(p: anytype) *v.vs_battle_uiEquipment {
    const o: ?*v.vs_battle_uiEquipment = @ptrCast(@alignCast(p));
    return o.?;
}

fn asGem(p: anytype) *v.vs_main_inventoryGem {
    const o: ?*v.vs_main_inventoryGem = @ptrCast(@alignCast(p));
    return o.?;
}

pub const stubs = struct {
    pub fn vs_battle_copyUiEquipmentStats(ctx: *zd.Ctx, target: anytype, equipment: anytype) void {
        const armor = asArmor(target);
        const equip = asEquipment(equipment);
        if (ctx.value(u1) == 1) armor.maxDp = ctx.value(u16);
        if (ctx.value(u1) == 1) equip.currentDp = ctx.value(u16);
    }

    pub fn vs_battle_copyUiGemStats(ctx: *zd.Ctx, gem: anytype, equipment: anytype) void {
        const g = asGem(gem);
        const equip = asEquipment(equipment);
        if (ctx.value(u1) == 1) g.id = ctx.value(u16);
        if (ctx.value(u1) == 1) equip.id = ctx.value(u16);
    }
};
