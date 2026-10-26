//! zig_diff spec: _dropWeaponRand -> drop_weapon_rand.dropWeaponRand (146C.c).
//! Inputs: a looted weapon and a base weapon in the arena. The base's dropRate
//! and the getRand result (any c_int, including negative and extreme values) are
//! set so the roll is equal to, below, or above the drop rate. Each of the three
//! gems is empty or holds an id with and without the sign bit, so the copy loop
//! takes both sides of its test for every slot. The copy callees are recording
//! stubs that write the looted fields they fill, and the name memcpy is traced.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").dropWeaponRand));

pub const classes = [_][:0]const u8{ "roll-equal", "roll-below", "roll-above" };

/// The roll the getRand stub returns for this iteration (set by prepare).
var roll_result: c_int = 0;

/// Casts a stub argument (optional or not) to a view pointer.
fn to(comptime T: type, p: anytype) *T {
    if (@typeInfo(@TypeOf(p)) == .optional) return @ptrCast(@alignCast(p.?));
    return @ptrCast(@alignCast(p));
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const looted = ctx.alloc(v.vs_battle_lootedWeapon);
    const base = ctx.alloc(v.vs_battle_uiWeapon);
    base.dropRate = ctx.pick(u8, &.{ 0, 1, 127, 128, 254, 255 });
    roll_result = ctx.pick(c_int, &.{ -1, 0, 1, 127, 128, 254, 255, 256, std.math.minInt(c_int), std.math.maxInt(c_int) });
    if (ctx.chance(3)) roll_result = @as(c_int, base.dropRate);
    for (&base.gems) |*g| {
        g.id = if (ctx.chance(3)) 0 else ctx.pick(u16, &.{ 1, 0x7FFF, 0x8000, 0xFFFF });
    }
    return .{ looted, base };
}

pub fn classify(args: Args) usize {
    const base = args[1].?;
    const rate: c_int = @as(c_int, base.dropRate);
    if (roll_result == rate) return 0;
    return if (roll_result < rate) 1 else 2;
}

pub const stubs = struct {
    pub fn vs_main_getRand(ctx: *zd.Ctx, n: anytype) c_int {
        _ = ctx;
        _ = n;
        return roll_result;
    }

    pub fn vs_main_memcpy(ctx: *zd.Ctx, dest: anytype, src: anytype, sz: anytype) void {
        _ = ctx;
        _ = dest;
        _ = src;
        _ = sz;
    }

    pub fn vs_battle_copyUiBladeStats(ctx: *zd.Ctx, dropBlade: anytype, targetBlade: anytype) void {
        _ = targetBlade;
        const b = to(v.vs_main_inventoryBlade, dropBlade);
        b.id = ctx.value(u8);
        b.cost = ctx.value(u8);
        if (ctx.value(u1) == 1) b.maxDp = ctx.value(u16);
    }

    pub fn vs_battle_copyUiGripStats(ctx: *zd.Ctx, dropGrip: anytype, targetGrip: anytype) void {
        _ = targetGrip;
        const g = to(v.vs_main_inventoryGrip, dropGrip);
        g.id = ctx.value(u16);
        if (ctx.value(u1) == 1) g.strength = ctx.value(i8);
    }

    pub fn vs_battle_copyUiGemStats(ctx: *zd.Ctx, dropGem: anytype, targetGem: anytype) void {
        _ = targetGem;
        const g = to(v.vs_main_inventoryGem, dropGem);
        g.id = ctx.value(u16);
        g.gemEffects = ctx.value(u8);
    }
};
