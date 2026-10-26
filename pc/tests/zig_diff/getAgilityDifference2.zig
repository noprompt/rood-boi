//! zig_diff spec: _getAgilityDifference2 -> get_agility_difference2.getAgilityDifference2 (146C.c).
//! Inputs: two hit entities whose actors (16 table entries, any index 0-15) carry random
//! or small-range agility stats, a random or edge-valued targetLimb (-128..127 in the random
//! class, 0..5 in the exact ones), random risk and weaponDrawn bits (both sides, drawn and
//! undrawn), and a gem buff pair plus variance set by prepare. Exact classes pick the final
//! agiDiff (0, 255, other values near the clamp, or a same-actor pair) by solving for the
//! defense buff, so the `< 0` and `== 255` comparisons see equal sides. addVariance covers
//! zero, positive and negative values.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getAgilityDifference2));

pub const classes = [_][:0]const u8{
    "random",
    "exact-0",
    "exact-255",
    "exact-other",
    "same-actor",
    "variance",
};

/// Gem buffs and the variance the stubs return, set by prepare (the same in both runs).
var attack_buff: c_short = 0;
var defense_buff: c_short = 0;
var variance_val: c_int = 0;
var cls: usize = 0;

pub const stubs = struct {
    // Neither callee changes anything the C reads back: the C only uses their results.
    pub fn _getAttackGemBuff(ctx: *zd.Ctx, action: anytype, actor: anytype) c_short {
        _ = ctx;
        _ = action;
        _ = actor;
        return attack_buff;
    }
    pub fn _getDefenseGemBuff(ctx: *zd.Ctx, action: anytype, actor: anytype, hit: anytype) c_short {
        _ = ctx;
        _ = action;
        _ = actor;
        _ = hit;
        return defense_buff;
    }
    pub fn vs_main_getRandSmoothed(ctx: *zd.Ctx, n: anytype) c_int {
        _ = ctx;
        _ = n;
        return variance_val;
    }
};

/// Sum of the C's agility terms for one side (before the risk scaling).
fn sideSum(a: *v.vs_battle_actor2, drawn: bool) i64 {
    var s: i64 = @as(i64, a.agility) + @as(i64, a.accessory.currentAgility);
    for (a.limbs) |limb| s += @as(i64, limb.armor.currentAgility);
    if (drawn) s += @as(i64, a.weapon.currentAgility) + @as(i64, a.shield.currentAgility);
    return s;
}

/// Small agility terms and risk 0, so the scaling is exact and the sums fit a c_short buff.
fn smallAgi(ctx: *zd.Ctx, a: *v.vs_battle_actor2) void {
    a.risk = 0;
    a.agility = ctx.range(u16, 0, 200);
    a.accessory.currentAgility = ctx.range(i16, -300, 100);
    a.weapon.currentAgility = ctx.range(i16, -300, 100);
    a.shield.currentAgility = ctx.range(i16, -300, 100);
    for (&a.limbs) |*l| l.armor.currentAgility = ctx.range(i16, -300, 100);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    // Room below the target's actor so a negative targetLimb reads memory the harness owns.
    _ = ctx.allocBytes(32 * 1024, 16);
    const tgt2 = ctx.alloc(v.vs_battle_actor2);
    const src2 = ctx.alloc(v.vs_battle_actor2);
    const action = ctx.alloc(v.vs_action_t);
    const source = ctx.alloc(v._hitEntity_t);
    const target = ctx.alloc(v._hitEntity_t);

    // The 16 battle actors the C indexes; each points at one of the two actor2 blocks.
    const tbl = v.g.vs_battle_actors();
    for (0..16) |i| {
        const a = ctx.alloc(v.vs_battle_actor);
        tbl[i] = a;
        psx.put(&a.stats, if (ctx.chance(2)) src2 else tgt2);
    }

    const kind: usize = switch (ctx.range(u8, 0, 10)) {
        0...2 => 0,
        3...4 => 1,
        5...6 => 2,
        7 => 3,
        8 => 4,
        else => 5,
    };
    cls = kind;
    const exact = kind != 0;

    const srcIdx = ctx.range(u8, 0, 15);
    const tgtIdx = if (kind == 4) srcIdx else ctx.range(u8, 0, 15);
    source.unk0.targetActor = srcIdx;
    target.unk0.targetActor = tgtIdx;
    // The target's entry wins when both sides name one entry: then both sides share tgt2.
    psx.put(&tbl[srcIdx].?.stats, src2);
    psx.put(&tbl[tgtIdx].?.stats, tgt2);
    const sa = psx.get(tbl[srcIdx].?.stats).?;
    const ta = psx.get(tbl[tgtIdx].?.stats).?;
    sa.unk957 = ctx.range(u8, 0, 15);
    ta.unk957 = ctx.range(u8, 0, 15);

    target.unk0.targetLimb = if (exact)
        ctx.range(i8, 0, 5)
    else
        ctx.pick(i8, &.{ 0, 1, 5, -1, 6, 127, -128 });

    action.cost = ctx.int(u8);
    if (exact) {
        smallAgi(ctx, sa);
        smallAgi(ctx, ta);
    }

    const addVariance: c_int = if (kind == 5)
        ctx.edge(c_int, &.{ 1, -1, 2 })
    else
        ctx.pick(c_int, &.{ 0, 1, -1 });
    variance_val = ctx.range(c_int, -5, 15);

    if (!exact) {
        attack_buff = ctx.int(c_short);
        defense_buff = ctx.int(c_short);
    } else {
        attack_buff = ctx.range(c_short, -100, 100);
        const drawnS = (tbl[sa.unk957].?.weaponDrawn & 1) != 0;
        const drawnT = (tbl[ta.unk957].?.weaponDrawn & 1) != 0;
        const limb: usize = @intCast(target.unk0.targetLimb);
        const sv: i64 = sideSum(sa, drawnS);
        const tv: i64 = sideSum(ta, drawnT) + @as(i64, ta.limbs[limb].agilityDefenseBonus);
        const pre: i64 = sv - tv + 130 - @as(i64, action.cost);
        const base: i64 = if (addVariance != 0) pre - 5 + @as(i64, variance_val) else pre;
        const desired: i64 = switch (kind) {
            1 => @as(i64, 0),
            2 => @as(i64, 255),
            3, 4 => @as(i64, ctx.range(i32, -5, 300)),
            else => @as(i64, ctx.range(i32, -5, 260)),
        };
        defense_buff = @intCast(base + @as(i64, attack_buff) - desired);
    }

    const hit = ctx.pick(c_int, &.{ 0, 1, -1, 255 });
    return .{ action, source, target, hit, addVariance };
}

pub fn classify(args: Args) usize {
    _ = args;
    return cls;
}
