//! zig_diff spec: func_80086754 -> func_80086754.func_80086754 (146C.c).
//! Inputs: a random arg0 whose bits are sparse (each bit about one in four),
//! with the two affinity fields (0x01E00000 and 0x1E000000) drawn from their
//! single-bit cases, multi-bit defaults and zero; and a vs_battle_actor2 in
//! the arena whose statuses are sometimes a subset of arg0 (so the cleared
//! status groups read as newly gone), whose weapon, shield and limb ids are
//! sometimes zero, whose affinities sit on the 50 and -100 edges, whose limb
//! hp and maxHp include 2 and 0, and whose unk34/unk35 limb indices run past
//! the six limbs (the arena holds them). The getRand, affinity-recalc and
//! armor-recalc stubs write the fields the C reads back.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80086754));

pub const classes = [_][:0]const u8{ "no-affinity-bits", "affinity-case", "affinity-default" };

pub const stubs = struct {
    pub fn vs_main_getRand(ctx: *zd.Ctx, n: anytype) c_int {
        _ = n;
        if (ctx.value(u2) == 0) return 0;
        return ctx.value(c_int);
    }

    pub fn _calculateWeaponClassAffinity(ctx: *zd.Ctx, p: anytype) void {
        const a: *v.vs_battle_actor2 = @ptrCast(@alignCast(p));
        a.shield.base.affinities[ctx.value(u3)] = ctx.value(i8);
    }

    pub fn _calculateShieldClassAffinity(ctx: *zd.Ctx, p: anytype) void {
        const a: *v.vs_battle_actor2 = @ptrCast(@alignCast(p));
        const k = ctx.value(u3) % 6;
        a.limbs[k].armor.armor.affinities[ctx.value(u3)] = ctx.value(i8);
    }

    pub fn _calculateArmorClassAffinity(ctx: *zd.Ctx, p: anytype, i: anytype) void {
        const a: *v.vs_battle_actor2 = @ptrCast(@alignCast(p));
        const k: usize = @intCast(i);
        a.limbs[(k + 1) % 6].armor.armor.id = ctx.value(u16);
    }
};

fn makeArg0(ctx: *zd.Ctx) c_int {
    var bits: u32 = ctx.int(u32) & ctx.int(u32);
    bits &= ~@as(u32, 0x01E0_0000 | 0x1E00_0000);
    bits |= ctx.edge(u32, &.{ 0, 0x0020_0000, 0x0040_0000, 0x0080_0000, 0x0100_0000, 0x0060_0000, 0x01E0_0000 });
    bits |= ctx.edge(u32, &.{ 0, 0x0200_0000, 0x0400_0000, 0x0800_0000, 0x1000_0000, 0x0600_0000, 0x1E00_0000 });
    return @bitCast(bits);
}

fn fillAff(ctx: *zd.Ctx, arr: *[8]i8) void {
    for (arr) |*x| x.* = ctx.pick(i8, &.{ 49, 50, 51, -100, -99, -101, 127, -128 });
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = makeArg0(ctx);
    const a = ctx.alloc(v.vs_battle_actor2);

    a.statuses = if (ctx.chance(2)) @as(i32, arg0) & ctx.int(i32) else ctx.int(i32);
    a.unk957 = ctx.edge(u8, &.{ 0, 0, 1, 3 });
    a.weapon.blade.id = ctx.edge(u16, &.{ 0, 0, 1, 0x7FFF, 0x8000 });
    a.shield.base.id = ctx.edge(u16, &.{ 0, 0, 1, 0x7FFF, 0x8000 });
    fillAff(ctx, &a.weapon.blade.affinities);
    fillAff(ctx, &a.shield.base.affinities);
    for (0..6) |i| {
        const limb = &a.limbs[i];
        limb.armor.armor.id = ctx.edge(u16, &.{ 0, 0, 1, 0x7FFF, 0x8000 });
        fillAff(ctx, &limb.armor.armor.affinities);
        limb.hp = ctx.pick(i16, &.{ 0, 1, 2, 2, 3, -1 });
        limb.maxHp = ctx.pick(i16, &.{ 0, 0, 1, -1 });
    }
    psx.setBits(a, "unk34", ctx.pick(u8, &.{ 0, 1, 5, 6, 7, 255 }));
    psx.setBits(a, "unk35", ctx.pick(u8, &.{ 0, 1, 5, 6, 7, 255 }));

    return .{ arg0, a };
}

fn isSingle(x: u32) bool {
    return (x & (x -% 1)) == 0;
}

pub fn classify(args: Args) usize {
    const arg0: u32 = @bitCast(args[0]);
    const g1 = arg0 & 0x01E0_0000;
    const g2 = arg0 & 0x1E00_0000;
    if (g1 == 0 and g2 == 0) return 0;
    if (isSingle(g1) and isSingle(g2)) return 1;
    return 2;
}
