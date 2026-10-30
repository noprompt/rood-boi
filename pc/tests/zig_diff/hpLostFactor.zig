//! zig_diff spec: _hpLostFactor -> hp_lost_factor.hpLostFactor (146C.c).
//! Inputs: an action whose hitParams entry (index 0-7, read through byteAt
//! inside the 52-byte struct) carries a random 5-bit statFactor; a hit entity
//! whose target slot is 0-15, holding an actor whose stats hold random i16
//! maxHP and currentHP (equal, lower, or higher, so v is negative and v / 10
//! truncates toward zero); a D_800F19CC block whose unk0 is often 0, 1 or the
//! u32 extremes (unk0 - 1 wraps in unsigned arithmetic); an unused arg2 that
//! is sometimes null; a random unused arg4. The C has no branch, no comparison
//! and no call, so the value edges are the sign of v, the division of a
//! negative v, and the unsigned wrap of the global's unk0.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hpLostFactor));

pub const classes = [_][:0]const u8{ "hp-gained", "no-hp-lost", "unk0-wrap", "hp-lost" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const hit = ctx.alloc(v._hitEntity_t);
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    const dmg = ctx.alloc(v.D_800F19CC_t);
    const other: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);

    // The target slot and its actor (the C dereferences both, no null test).
    const slot = ctx.range(u8, 0, 15);
    hit.unk0.targetActor = slot;
    v.g.vs_battle_actors()[slot] = actor;
    psx.put(&actor.stats, stats);

    stats.maxHP = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 999 });
    if (ctx.chance(4)) {
        stats.currentHP = stats.maxHP;
    } else {
        stats.currentHP = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 999 });
    }

    // The global the C dereferences with no null test.
    dmg.unk0 = ctx.pick(u32, &.{ 0, 1, 2, 0xFFFF_FFFF, 0x8000_0000 });
    v.g.D_800F19CC().* = dmg;

    // The hit parameter the C reads: entry idx, with a random statFactor.
    const idx = ctx.range(c_int, 0, 7);
    const hp = psx.byteAt(
        v.vs_action_t_hitParams,
        action,
        @offsetOf(v.vs_action_t, "hitParams") + 4 * @as(isize, idx),
    );
    psx.setBits(hp, "statFactor", ctx.int(u5));

    return .{ action, hit, other, idx, ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const stats = psx.get(v.g.vs_battle_actors()[args[1].?.unk0.targetActor].?.stats).?;
    if (stats.currentHP > stats.maxHP) return 0;
    if (stats.currentHP == stats.maxHP) return 1;
    if (v.g.D_800F19CC().*.?.unk0 == 0) return 2;
    return 3;
}
