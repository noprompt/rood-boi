//! zig_diff spec: func_800801E0 -> func_800801E0.func_800801E0 (146C.c).
//! Inputs: an action (sometimes null, which the C never reads), an entity whose
//! targetActor is one of the 16 vs_battle_actors slots, and that slot's actor
//! with a valid arena stats block (the C always dereferences it, so it is never
//! null). The six limbs get maxHp and hp from edge values (0, 1, -1, the i16
//! extremes), with hp near maxHp, equal to it, or random, so the damage sum is
//! zero, negative, small positive or large positive. A mode also makes two limbs
//! cancel to a sum of 1, so amount * diff / sum overflows the i16 table and the
//! i16 effect. amount is any short, negative and extreme values included.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800801E0));

pub const classes = [_][:0]const u8{ "no-live-limb", "zero-sum", "negative-sum", "small-positive-sum", "positive-sum" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    const entity = ctx.alloc(v._hitEntity_t);
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);

    const idx = ctx.range(u8, 0, 15);
    entity.unk0.targetActor = idx;
    v.g.vs_battle_actors()[idx] = actor;
    psx.put(&actor.stats, stats);

    for (&stats.limbs) |*limb| {
        limb.maxHp = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 100 });
        limb.hp = if (ctx.chance(2)) limb.maxHp -% ctx.range(i16, 0, 300) else ctx.int(i16);
    }

    const mode = ctx.range(u8, 0, 9);
    switch (mode) {
        0 => {
            for (&stats.limbs) |*limb| limb.maxHp = 0;
        },
        1 => {
            for (&stats.limbs) |*limb| limb.hp = limb.maxHp;
        },
        2 => {
            // Two limbs cancel to a damage sum of 1: the quotient is amount * 65535.
            for (&stats.limbs) |*limb| limb.maxHp = 0;
            const k1 = ctx.range(usize, 0, 5);
            var k2 = ctx.range(usize, 0, 5);
            if (k2 == k1) k2 = (k1 + 1) % 6;
            stats.limbs[k1].maxHp = 32767;
            stats.limbs[k1].hp = -32768;
            stats.limbs[k2].maxHp = -32768;
            stats.limbs[k2].hp = 32766;
        },
        else => {},
    }

    const amount = ctx.pick(c_short, &.{ 0, 1, -1, 100, -100, 32767, -32768 });
    return .{ action, entity, amount };
}

pub fn classify(args: Args) usize {
    const entity = args[1].?;
    const actor = v.g.vs_battle_actors()[entity.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    var sum: i64 = 0;
    var live = false;
    for (stats.limbs) |limb| {
        if (limb.maxHp != 0) {
            live = true;
            sum += @as(i64, limb.maxHp) - limb.hp;
        }
    }
    if (!live) return 0;
    if (sum == 0) return 1;
    if (sum < 0) return 2;
    if (sum <= 4) return 3;
    return 4;
}
