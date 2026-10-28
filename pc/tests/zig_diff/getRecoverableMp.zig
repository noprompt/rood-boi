//! zig_diff spec: _getRecoverableMp -> get_recoverable_mp.getRecoverableMp (146C.c).
//! Inputs: a hit entity whose targetActor picks one of the 16 battle actor
//! slots (the table's room). Every slot holds a valid actor; the target's
//! stats block carries maxMP and currentMP drawn from the i16 edges (-1, 0, 1,
//! 32767, -32768), so the difference is zero, positive, negative, or wraps
//! past 16 bits when the short result is truncated. The C has no branches;
//! its value edges are the zero difference, its sign, and that overflow.
//! arg0, arg1, arg3 and arg4 are unused by the C; arg0 and arg1 are null
//! sometimes.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getRecoverableMp));

pub const classes = [_][:0]const u8{ "zero", "positive", "negative", "wraps" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    const target: u8 = ctx.range(u8, 0, 15);

    // Every slot gets a valid actor; the other slots share one stats block.
    const shared = ctx.alloc(v.vs_battle_actor2);
    shared.maxMP = ctx.int(i16);
    shared.currentMP = ctx.int(i16);
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        psx.put(&actor.stats, shared);
        table[i] = actor;
    }

    // The target's own stats block, with the edge values.
    const stats = ctx.alloc(v.vs_battle_actor2);
    stats.maxMP = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    stats.currentMP = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    if (ctx.chance(4)) stats.currentMP = stats.maxMP;
    psx.put(&table[target].?.stats, stats);

    const entity = ctx.alloc(v._hitEntity_t);
    entity.unk0.targetActor = target;

    const a0: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    const a1: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    return .{ a0, a1, entity, ctx.int(c_int), ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const entity = args[2].?;
    const actor = v.g.vs_battle_actors()[entity.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    const d = @as(i32, stats.maxMP) - @as(i32, stats.currentMP);
    if (d == 0) return 0;
    if (d > 32767 or d < -32768) return 3;
    return if (d > 0) 1 else 2;
}
