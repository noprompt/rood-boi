//! zig_diff spec: _getAgilityDifference -> get_agility_difference.getAgilityDifference (146C.c).
//! Inputs: two hit entities whose actors come from the 16-entry actor table (every entry
//! set). Five of seven modes pin the pre-clamp value with the defense/attack gem knobs:
//! the source risk is 100 (its value is 0) and the target risk is 0 with only its agility
//! and one limb bonus nonzero, so agiDiff = 100 - T + attack - defense. Those modes give
//! exact 0, exact 255, negative, above 255 and 1..254 results. The other two modes (variance,
//! random) draw every field: risks 0..200 so the products cannot overflow, full-range
//! agilities (u16 and i16), limb index -1..7, any weaponDrawn, any addVariance and hitNumber.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getAgilityDifference));

pub const classes = [_][:0]const u8{
    "exact-zero",
    "exact-255",
    "exact-negative",
    "exact-high",
    "exact-in-range",
    "variance",
    "random",
};

/// The class of the current iteration, set by prepare.
var mode: usize = 0;
/// Gem buff results for this iteration (the stubs return them most calls).
var gem_att: c_short = 0;
var gem_def: c_short = 0;

fn fillStats(ctx: *zd.Ctx, s: *v.vs_battle_actor2) void {
    s.agility = ctx.int(u16);
    s.risk = ctx.range(u16, 0, 200);
    s.accessory.currentAgility = ctx.int(i16);
    s.weapon.currentAgility = ctx.int(i16);
    s.shield.currentAgility = ctx.int(i16);
    for (&s.limbs) |*l| {
        l.agilityDefenseBonus = ctx.int(i8);
        l.armor.currentAgility = ctx.int(i16);
    }
    s.unk957 = ctx.range(u8, 0, 15);
}

pub const stubs = struct {
    // Stub results: the variance is 0..10 as the real smoothed roll is.
    pub fn vs_main_getRandSmoothed(ctx: *zd.Ctx, n: anytype) c_int {
        _ = n;
        return @as(c_int, ctx.value(u8) % 11);
    }

    // Both gem buffs only read the action and the actor (gem slots and effects):
    // they write nothing the C reads back, so they only return a value.
    pub fn _getAttackGemBuff(ctx: *zd.Ctx, action: anytype, actor: anytype) c_short {
        _ = action;
        _ = actor;
        if (ctx.value(u8) < 200) return gem_att;
        return ctx.value(c_short);
    }

    pub fn _getDefenseGemBuff(ctx: *zd.Ctx, action: anytype, actor: anytype, hit: anytype) c_short {
        _ = action;
        _ = actor;
        _ = hit;
        if (ctx.value(u8) < 200) return gem_def;
        return ctx.value(c_short);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const m: u8 = ctx.range(u8, 0, 255) % 7;
    mode = m;
    const exact = mode <= 4;

    const action: ?*v.vs_action_t = if (ctx.chance(8)) null else ctx.alloc(v.vs_action_t);
    const source = ctx.alloc(v._hitEntity_t);
    const target = ctx.alloc(v._hitEntity_t);

    const a: u8 = ctx.range(u8, 0, 15);
    const b: u8 = if (exact) (a + ctx.range(u8, 1, 15)) % 16 else ctx.range(u8, 0, 15);
    source.unk0.targetActor = a;
    target.unk0.targetActor = b;
    target.unk0.targetLimb = if (exact) ctx.range(i8, 0, 5) else ctx.range(i8, -1, 7);
    source.unk0.targetLimb = ctx.int(i8);

    const srcStats = ctx.alloc(v.vs_battle_actor2);
    const tgtStats = ctx.alloc(v.vs_battle_actor2);
    fillStats(ctx, srcStats);
    fillStats(ctx, tgtStats);

    // The actor table: 16 entries, each a valid actor. Entry a holds the source
    // stats, entry b the target stats (when a == b the target's block wins, as in C).
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        actor.weaponDrawn = ctx.int(i32);
        psx.put(&actor.stats, if (i == b) tgtStats else srcStats);
        table[i] = actor;
    }

    var addVar: c_int = 0;
    if (exact) {
        // Source value is 0 (risk 100); target value is its agility plus one limb bonus.
        srcStats.risk = 100;
        tgtStats.risk = 0;
        tgtStats.agility = ctx.range(u16, 0, 300);
        tgtStats.accessory.currentAgility = 0;
        tgtStats.weapon.currentAgility = 0;
        tgtStats.shield.currentAgility = 0;
        for (&tgtStats.limbs) |*l| l.armor.currentAgility = 0;
        const tl: usize = @intCast(target.unk0.targetLimb);
        const bonus = ctx.int(i8);
        tgtStats.limbs[tl].agilityDefenseBonus = bonus;

        const T: i32 = @as(i32, tgtStats.agility) + @as(i32, bonus);
        const gA: i16 = ctx.range(i16, -40, 40);
        const D: i32 = switch (mode) {
            0 => 0,
            1 => 255,
            2 => ctx.range(i32, -300, -1),
            3 => ctx.range(i32, 256, 600),
            else => ctx.range(i32, 1, 254),
        };
        // agiDiff = 100 - T + gA - gD must equal D.
        const gd: i32 = 100 - T + @as(i32, gA) - D;
        gem_att = @intCast(gA);
        gem_def = @intCast(gd);
    } else {
        gem_att = @intCast(ctx.int(i16));
        gem_def = @intCast(ctx.int(i16));
        addVar = if (mode == 5)
            ctx.pick(c_int, &.{ 1, -1, 2, std.math.minInt(c_int), std.math.maxInt(c_int) })
        else
            ctx.pick(c_int, &.{ 0, 1, -1, std.math.minInt(c_int), std.math.maxInt(c_int) });
    }

    const hitNumber: c_int = ctx.pick(c_int, &.{ 0, 1, -1, 6, 7, std.math.maxInt(c_int) });
    return .{ action, source, target, hitNumber, addVar };
}

pub fn classify(args: Args) usize {
    _ = args;
    return mode;
}
