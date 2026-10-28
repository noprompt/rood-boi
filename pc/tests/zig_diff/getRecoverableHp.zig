//! zig_diff spec: _getRecoverableHp -> get_recoverable_hp.getRecoverableHp (146C.c).
//! Inputs: an entity whose targetActor (0-15) picks a battle actor from
//! vs_battle_actors. That actor's stats block, reached through its guest
//! pointer field, holds currentHP and maxHP as any i16, often equal and often
//! at the ends of the range, so the difference wraps the short result. arg0
//! is null or an arena object, arg1 an arena object, arg3 and arg4 random
//! (the C never reads any of them).
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getRecoverableHp));

pub const classes = [_][:0]const u8{ "equal", "plain", "wraps-high", "wraps-low" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    const entity = ctx.alloc(v._hitEntity_t);

    // The table has 16 slots; only the slot the C reads is set.
    const slot = ctx.range(u8, 0, 15);
    entity.unk0.targetActor = slot;
    psx.put(&actor.stats, stats);
    v.g.vs_battle_actors()[slot] = actor;

    stats.currentHP = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    stats.maxHP = if (ctx.chance(4))
        stats.currentHP
    else
        ctx.pick(i16, &.{ 0, -1, 32767, -32768, 999 });

    const arg0: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    return .{ arg0, ctx.alloc(v._hitEntity_t), entity, ctx.int(c_int), ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const entity = args[2].?;
    const actor = v.g.vs_battle_actors()[entity.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    const diff = @as(i32, stats.maxHP) - @as(i32, stats.currentHP);
    if (diff == 0) return 0;
    if (diff > 32767) return 2;
    if (diff < -32768) return 3;
    return 1;
}
