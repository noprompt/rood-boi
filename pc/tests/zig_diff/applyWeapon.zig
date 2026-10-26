//! zig_diff spec: vs_battle_applyWeapon -> apply_weapon.applyWeapon (146C.c).
//! Inputs: a target weapon and an inventory weapon that is null, or has any
//! blade/grip index in {0,1,2,16,17} (16 and 17 read one past the blades and
//! grips arrays, still inside vs_main_inventory), any gem slots in {0,1,2,47,48}
//! and any name bytes. The global inventory is random bytes, so every stat the
//! copy stubs or the C reads through it is random. The allocator and bzero
//! stubs work on arena memory; the stat-copy and apply stubs write the
//! destination fields, so the state the C hands on is observable.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").applyWeapon));

pub const classes = [_][:0]const u8{ "null-source", "no-parts", "parts-no-gems", "gems-only", "parts-and-gems" };

pub const stubs = struct {
    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        return @ptrCast(ctx.allocBytes(@intCast(size), 16));
    }

    pub fn vs_main_freeHeapR(ctx: *zd.Ctx, p: anytype) void {
        _ = ctx;
        _ = p;
    }

    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const b: [*]u8 = @ptrCast(p.?);
        @memset(b[0..@intCast(n)], 0);
    }

    pub fn vs_battle_copyInventoryBladeStats(ctx: *zd.Ctx, dst: anytype, src: anytype) void {
        _ = src;
        const e: *v.vs_battle_uiEquipment = @ptrCast(@alignCast(dst.?));
        e.currentDp = ctx.value(u16);
        e.maxPp = ctx.value(u16);
    }

    pub fn vs_battle_copyInventoryGripStats(ctx: *zd.Ctx, dst: anytype, src: anytype) void {
        _ = src;
        const e: *v.vs_battle_uiEquipment = @ptrCast(@alignCast(dst.?));
        e.currentDp = ctx.value(u16);
        e.strength = ctx.value(i8);
    }

    pub fn vs_battle_copyInventoryGemStats(ctx: *zd.Ctx, dst: anytype, src: anytype) void {
        _ = src;
        const e: *v.vs_battle_uiEquipment = @ptrCast(@alignCast(dst.?));
        e.currentPp = ctx.value(u16);
        e.gemEffects = ctx.value(u8);
    }

    pub fn vs_battle_applyWeaponStats(ctx: *zd.Ctx, target: anytype, inter: anytype) void {
        _ = inter;
        const t: *v.vs_battle_uiWeapon = @ptrCast(@alignCast(target.?));
        t.currentDp = ctx.value(u16);
        t.damageType = ctx.value(u8);
        t.currentStr = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_battle_uiWeapon);
    const source = ctx.alloc(v.vs_main_inventoryWeapon);
    if (ctx.chance(6)) return .{ target, null };
    source.index = ctx.int(u8);
    source.isEquipped = ctx.int(u8);
    source.blade = ctx.edge(u8, &.{ 0, 1, 2, 16, 17 });
    source.grip = ctx.edge(u8, &.{ 0, 1, 2, 16, 17 });
    for (&source.gems) |*g| {
        g.* = if (ctx.chance(3)) 0 else ctx.edge(u8, &.{ 1, 2, 47, 48 });
    }
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    const src = args[1] orelse return 0;
    const any_gem = src.gems[0] != 0 or src.gems[1] != 0 or src.gems[2] != 0;
    if (src.blade == 0 and src.grip == 0) return if (any_gem) 3 else 1;
    return if (any_gem) 4 else 2;
}
