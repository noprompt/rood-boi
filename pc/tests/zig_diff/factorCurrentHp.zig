//! zig_diff spec: _factorCurrentHp -> factor_current_hp.factorCurrentHp (146C.c).
//! Inputs: an action whose two hit parameters carry random statFactor bits
//! (arg3 also takes -1 and 2, which reach bytes still inside the struct), an
//! entity whose target slot is 0-15 with an actor in vs_battle_actors, a stats
//! block with edge currentHP values (negative, zero, extremes), and the global
//! D_800F19CC with unk0 zero (the "- 1" wraps) or an edge u32. The C has no
//! branches and no calls. The product is divided by 100 with truncation toward
//! zero, so negative HP is covered.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").factorCurrentHp));

pub const classes = [_][:0]const u8{ "unk0-zero", "hp-negative", "hp-zero", "other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const entity = ctx.alloc(v._hitEntity_t);
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    const d = ctx.alloc(v.D_800F19CC_t);

    // Both hit parameters get edge statFactor values; the rest stay random.
    for (0..2) |i| {
        psx.setBits(&action.hitParams[i], "statFactor", ctx.pick(u5, &.{ 0, 1, 31 }));
    }

    stats.currentHP = ctx.pick(i16, &.{ 0, 1, -1, 100, -100, 32767, -32768 });
    psx.put(&actor.stats, stats);

    // Only slots 0-15 exist in the table; the C reads exactly the one it indexes.
    const slot = ctx.range(u8, 0, 15);
    v.g.vs_battle_actors()[slot] = actor;
    entity.unk0.targetActor = slot;

    d.unk0 = if (ctx.chance(3)) 0 else ctx.pick(u32, &.{ 1, 2, 0xFFFF_FFFF, 0x8000_0000 });
    v.g.D_800F19CC().* = d;

    const arg1: ?*v._hitEntity_t = if (ctx.chance(4)) null else ctx.alloc(v._hitEntity_t);
    const arg3: c_int = ctx.edge(c_int, &.{ 0, 1, 2, -1 });
    return .{ action, arg1, entity, arg3, ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const entity = args[2].?;
    const d = v.g.D_800F19CC().*.?;
    if (d.unk0 == 0) return 0;
    const actor = v.g.vs_battle_actors()[entity.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    if (stats.currentHP < 0) return 1;
    if (stats.currentHP == 0) return 2;
    return 3;
}
