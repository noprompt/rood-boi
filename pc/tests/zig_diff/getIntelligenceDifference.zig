//! zig_diff spec: _getIntelligenceDifference -> get_intelligence_difference.getIntelligenceDifference (146C.c).
//! Inputs: two hit entities that name table actors. All 16 table slots are arena
//! actors; the two named slots point at the source and target stats blocks (or at
//! one shared block for the same-actor case). Four exact modes pin the pre-clamp
//! difference below zero, at 0, at 255 and above 255 by choosing the source's
//! accessory intelligence against the gem and variance stub returns, with every
//! target contribution zeroed. A random mode fills each field the C reads with
//! edge values (u16 risk and intelligence, i16 HP and armour, any i8 limb index,
//! any i32 weaponDrawn, any addVariance). The gem buffs only read their arguments;
//! the variance stub returns a value the spec chose.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getIntelligenceDifference));

pub const classes = [_][:0]const u8{ "below-zero", "exact-zero", "exact-255", "above-255", "same-actor", "random" };

var mode: usize = 5;
var gem_atk: c_short = 0;
var gem_def: c_short = 0;
var variance_val: c_int = 0;

pub const stubs = struct {
    pub fn vs_main_getRandSmoothed(ctx: *zd.Ctx, n: anytype) c_int {
        _ = ctx;
        _ = n;
        return variance_val;
    }
    pub fn _getAttackGemBuff(ctx: *zd.Ctx, action: anytype, actor: anytype) c_short {
        _ = ctx;
        _ = action;
        _ = actor;
        return gem_atk;
    }
    pub fn _getDefenseGemBuff(ctx: *zd.Ctx, action: anytype, actor: anytype, hitNumber: anytype) c_short {
        _ = ctx;
        _ = action;
        _ = actor;
        _ = hitNumber;
        return gem_def;
    }
};

fn fillRandom(ctx: *zd.Ctx, a: *v.vs_battle_actor2) void {
    a.risk = ctx.pick(u16, &.{ 0, 50, 99, 100, 101, 200, 0xFFFF });
    a.intelligence = ctx.pick(u16, &.{ 0, 1, 100, 255, 256, 0xFFFF });
    a.accessory.currentInt = ctx.pick(i16, &.{ 0, 1, -1, 100, 32767, -32768 });
    a.weapon.currentInt = ctx.pick(i16, &.{ 0, 1, -1, 100, 32767, -32768 });
    a.shield.currentInt = ctx.pick(i16, &.{ 0, 1, -1, 100, 32767, -32768 });
    for (0..6) |i| a.limbs[i].armor.currentInt = ctx.pick(i16, &.{ 0, 1, -1, 100, 32767, -32768 });
    a.currentHP = ctx.pick(i16, &.{ 0, 1, -1, 255, 32767, -32768 });
    a.maxHP = ctx.edge(i16, &.{ 1, -1, 2, 100, 32767, -32768 });
    a.unk957 = ctx.range(u8, 0, 15);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const tbl = v.g.vs_battle_actors();
    const r = ctx.range(u8, 0, 11);
    mode = switch (r) {
        0, 1 => 0,
        2, 3 => 1,
        4, 5 => 2,
        6 => 3,
        7 => 4,
        else => 5,
    };

    const dummy = ctx.alloc(v.vs_battle_actor2);
    const sa2 = ctx.alloc(v.vs_battle_actor2);
    const ta2 = if (mode == 4) sa2 else ctx.alloc(v.vs_battle_actor2);
    const src = ctx.alloc(v._hitEntity_t);
    const tgt = ctx.alloc(v._hitEntity_t);
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);

    const si = ctx.range(u8, 0, 15);
    const ti: u8 = if (mode == 4) si else (si +% ctx.range(u8, 1, 15)) & 15;

    for (0..16) |k| {
        const a = ctx.alloc(v.vs_battle_actor);
        psx.put(&a.stats, dummy);
        a.weaponDrawn = ctx.int(i32);
        tbl[k] = a;
    }
    psx.put(&tbl[si].?.stats, sa2);
    psx.put(&tbl[ti].?.stats, ta2);

    src.unk0.targetActor = si;
    tgt.unk0.targetActor = ti;
    src.unk0.targetLimb = ctx.int(i8);
    tgt.unk0.targetLimb = ctx.edge(i8, &.{ -2, -1, 0, 1, 2, 3, 4, 5, 6, 7 });

    const addVar: c_int = if (mode <= 3)
        (if (ctx.chance(3)) 0 else ctx.edge(c_int, &.{ 1, -1, 0x40000000 }))
    else
        ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFFFFFF });

    if (mode == 4 or mode == 5) {
        fillRandom(ctx, sa2);
        if (mode == 5) fillRandom(ctx, ta2);
        gem_atk = ctx.pick(c_short, &.{ 0, 1, -1, 255, -255, 32767, -32768 });
        gem_def = ctx.pick(c_short, &.{ 0, 1, -1, 255, -255, 32767, -32768 });
        variance_val = ctx.pick(c_int, &.{ 0, 1, -1, 10, 2147483647, -2147483648 });
    } else {
        const f: c_int = switch (mode) {
            0 => ctx.range(c_int, -300, -1),
            1 => 0,
            2 => 255,
            else => ctx.range(c_int, 256, 400),
        };
        variance_val = ctx.range(c_int, 0, 10);
        gem_atk = ctx.range(c_short, -300, 300);
        gem_def = ctx.range(c_short, -300, 300);
        const adj: c_int = if (addVar != 0) -5 + variance_val else 0;
        const x: c_int = f - adj - @as(c_int, gem_atk) + @as(c_int, gem_def);

        // Source: risk 0 and only the accessory carries the value, so sv == x.
        sa2.risk = 0;
        sa2.intelligence = 0;
        sa2.accessory.currentInt = @intCast(x);
        sa2.weapon.currentInt = 0;
        sa2.shield.currentInt = 0;
        for (0..6) |i| sa2.limbs[i].armor.currentInt = 0;
        sa2.unk957 = ctx.range(u8, 0, 15);

        // Target: every contribution zero, so tv == 0 whatever risk and HP are.
        ta2.risk = ctx.int(u16);
        ta2.intelligence = 0;
        ta2.accessory.currentInt = 0;
        ta2.weapon.currentInt = 0;
        ta2.shield.currentInt = 0;
        for (0..6) |i| {
            ta2.limbs[i].armor.currentInt = 0;
            ta2.limbs[i].agilityDefenseBonus = 0;
        }
        psx.at(&ta2.limbs, tgt.unk0.targetLimb).agilityDefenseBonus = 0;
        ta2.currentHP = ctx.int(i16);
        ta2.maxHP = ctx.edge(i16, &.{ 1, -1, 100, 32767, -32768 });
        ta2.unk957 = ctx.range(u8, 0, 15);
    }

    const hit: c_int = ctx.pick(c_int, &.{ 0, 1, -1 });
    return .{ action, src, tgt, hit, addVar };
}

pub fn classify(args: Args) usize {
    _ = args;
    return mode;
}
