//! zig_diff spec: _dropShieldRand -> drop_shield_rand.dropShieldRand (146C.c).
//! Inputs: a looted shield and a UI shield, both in the arena. dropRate is 0
//! about a tenth of the time, otherwise an edge value. The roll stub returns
//! the rate itself half the time (so the `<` sees equal sides), a full c_int
//! (negative sometimes) a quarter of the time, and a byte otherwise. Gem ids
//! are zero or nonzero per slot, so every gem-copy branch and every loop exit
//! is taken. The copy callees write their output parameter.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").dropShieldRand));

pub const classes = [_][:0]const u8{ "rate-zero", "gems-none", "gems-some", "gems-all" };

/// The dropRate field the roll stub compares against (set by prepare).
var rate: ?*const u8 = null;

pub const stubs = struct {
    pub fn vs_main_getRand(ctx: *zd.Ctx, n: anytype) c_int {
        _ = n;
        return switch (ctx.value(u2)) {
            0, 1 => @as(c_int, rate.?.*),
            2 => ctx.value(c_int),
            3 => @as(c_int, ctx.value(u8)),
        };
    }

    pub fn vs_battle_copyUiEquipmentStats(ctx: *zd.Ctx, dst: anytype, src: anytype) void {
        _ = src;
        const d: *v.vs_main_inventoryArmor = @ptrCast(@alignCast(dst));
        d.id = ctx.value(u8);
        d.maxDp = ctx.value(u16);
        d.currentDp = ctx.value(u16);
        d.maxPp = ctx.value(u16);
        d.currentPp = ctx.value(u16);
    }

    pub fn vs_battle_copyUiGemStats(ctx: *zd.Ctx, dst: anytype, src: anytype) void {
        _ = src;
        const g: *v.vs_main_inventoryGem = @ptrCast(@alignCast(dst));
        g.id = ctx.value(u16);
        g.strength = ctx.value(i8);
        g.index = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const looted = ctx.alloc(v.vs_battle_lootedShield);
    const base = ctx.alloc(v.vs_battle_uiShield);
    base.dropRate = ctx.pick(u8, &.{ 0, 1, 127, 128, 255 });
    for (&base.gems) |*g| {
        g.id = if (ctx.chance(3)) 0 else ctx.pick(u16, &.{ 1, 0x8000, 0xFFFF });
    }
    rate = &base.dropRate;
    return .{ looted, base };
}

pub fn classify(args: Args) usize {
    const base = args[1].?;
    if (base.dropRate == 0) return 0;
    var nonzero: usize = 0;
    for (base.gems) |g| {
        if (g.id != 0) nonzero += 1;
    }
    if (nonzero == 0) return 1;
    return if (nonzero == 3) 3 else 2;
}
