//! zig_diff spec: _applyBattleAbilityEffect -> apply_battle_ability_effect.applyBattleAbilityEffect (146C.c).
//! Inputs: a random _hitEntity_t whose twelve effect selectors are each 0-3
//! (set through their bitfields), with stat deltas drawn from an edge list
//! (0, 1, -1, 999, 1000, the i16/u16 extremes), so clamps and "equal" tests
//! fire often. The target is actor id 0 a quarter of the time, else 1-15,
//! reached through vs_battle_actors[targetActor] and the owner's stats block.
//! Actor stats come from the same edge lists, so ordered tests see equal
//! sides. targetLimb is -1, 0, 1, 2, 5 or 6 (the armor branch indexes limbs
//! with it; -1 and 6 read outside the six-entry array but inside the struct
//! or the arena). The status callees rewrite the actor's statuses and
//! currentHP, as the real ones do, so the status loops see changing state.
//! func_800971D4 and func_80087578 are void and touch nothing the C reads back.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").applyBattleAbilityEffect));

pub const classes = [_][:0]const u8{ "target-0", "heal", "damage", "statuses", "other" };

/// The target's stats block, for the status callees to write into.
var g_actor: *v.vs_battle_actor2 = undefined;

fn e16(ctx: *zd.Ctx) i16 {
    return ctx.pick(i16, &.{ 0, 1, -1, 999, 1000, 32767, -32768 });
}

fn u16e(ctx: *zd.Ctx) u16 {
    return ctx.pick(u16, &.{ 0, 1, 999, 1000, 65535, 32768 });
}

fn i32e(ctx: *zd.Ctx) i32 {
    return ctx.pick(i32, &.{ 0, 1, -1, 0x4000_0000, std.math.minInt(i32) });
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const hit = ctx.alloc(v._hitEntity_t);
    const actor = ctx.alloc(v.vs_battle_actor2);
    const owner = ctx.alloc(v.vs_battle_actor);
    g_actor = actor;

    const target: u8 = if (ctx.chance(4)) 0 else ctx.range(u8, 1, 15);
    hit.unk0.targetActor = target;
    hit.unk0.targetLimb = ctx.edge(i8, &.{ -1, 0, 1, 2, 5, 6 });
    hit.unk0.unk3 = ctx.pick(u8, &.{ 4, 4, 0, 1, 255 });
    hit.unk0.hp = e16(ctx);
    hit.unk0.mp = e16(ctx);
    hit.risk = e16(ctx);
    hit.strength = e16(ctx);
    hit.intelligence = e16(ctx);
    hit.agility = e16(ctx);
    hit.maxHp = e16(ctx);
    hit.maxMp = e16(ctx);
    hit.removeStatuses = i32e(ctx);
    hit.inflictStatuses = i32e(ctx);
    if (ctx.chance(3)) hit.removeStatuses = 0;
    if (ctx.chance(3)) hit.inflictStatuses = 0;
    for (0..6) |i| {
        hit.limbs[i].effects.value0 = e16(ctx);
        hit.limbs[i].effects.value1 = e16(ctx);
    }
    hit.weaponDp = e16(ctx);
    hit.weaponPp = e16(ctx);
    hit.armorDp = e16(ctx);
    hit.shieldPp = e16(ctx);
    inline for (.{
        "hpEffect",           "mpEffect",        "riskEffect",       "strengthEffect",
        "intelligenceEffect", "agilityEffect",   "maxHpEffect",      "maxMpEffect",
        "weaponDpEffect",     "weaponPpEffect",  "armorDpEffect",    "shieldPpEffect",
    }) |name| {
        psx.setBits(hit, name, ctx.range(u2, 0, 3));
    }

    actor.currentHP = e16(ctx);
    actor.maxHP = e16(ctx);
    actor.currentMP = e16(ctx);
    actor.maxMP = e16(ctx);
    actor.risk = u16e(ctx);
    actor.strength = u16e(ctx);
    actor.totalStrength = u16e(ctx);
    actor.intelligence = u16e(ctx);
    actor.totalIntelligence = u16e(ctx);
    actor.agility = u16e(ctx);
    actor.totalAgility = u16e(ctx);
    actor.statuses = i32e(ctx);
    for (0..6) |i| {
        actor.limbs[i].hp = e16(ctx);
        actor.limbs[i].maxHp = e16(ctx);
        actor.limbs[i].armor.currentDp = u16e(ctx);
    }
    actor.weapon.currentPp = u16e(ctx);
    actor.weapon.maxPp = u16e(ctx);
    actor.weapon.currentDp = u16e(ctx);
    actor.weapon.maxDp = u16e(ctx);
    actor.shield.currentDp = u16e(ctx);
    actor.shield.currentPp = u16e(ctx);

    v.g.vs_battle_actors()[target] = owner;
    psx.put(&owner.stats, actor);

    return .{hit};
}

pub fn classify(args: Args) usize {
    const hit = args[0].?;
    if (hit.unk0.targetActor == 0) return 0;
    const hp = psx.getBits(hit, "hpEffect");
    if (hp == 2) return 1;
    if (hp == 1 or hp == 3) return 2;
    if (hit.inflictStatuses != 0 or hit.removeStatuses != 0) return 3;
    return 4;
}

pub const stubs = struct {
    // The status callees change the target's statuses and, sometimes, its HP:
    // the C re-reads both after each call.
    pub fn func_80093FEC(ctx: *zd.Ctx, id: anytype, zero: anytype, status: anytype, on: anytype) void {
        _ = id;
        _ = zero;
        _ = status;
        _ = on;
        if (ctx.value(u1) == 1) g_actor.currentHP = ctx.value(i16);
        if (ctx.value(u2) == 0) g_actor.statuses = ctx.value(i32);
    }

    pub fn func_80086754(ctx: *zd.Ctx, flag: anytype, a: anytype) void {
        _ = flag;
        _ = a;
        if (ctx.value(u1) == 1) g_actor.statuses = ctx.value(i32);
    }

    pub fn func_80086FA8(ctx: *zd.Ctx, flag: anytype, a: anytype) void {
        _ = flag;
        _ = a;
        if (ctx.value(u1) == 1) g_actor.statuses = ctx.value(i32);
    }
};
