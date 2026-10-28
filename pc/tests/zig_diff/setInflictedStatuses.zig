//! zig_diff spec: _setInflictedStatuses -> set_inflicted_statuses.setInflictedStatuses (146C.c).
//! Inputs: an arg0 in 0..4 (the last entry of vs_main_statusEffectParams), a
//! hit entity whose targetActor is 0..15 (each a non-null battle actor from
//! the arena), and a stats block whose unk957 is 128 half the time and
//! otherwise 0, 127, 129 or 255. Statuses, the params words and the entity's
//! inflictStatuses take sign-bit and zero edges as well as random values.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setInflictedStatuses));

pub const classes = [_][:0]const u8{ "unk957-not-128", "unk957-128" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    const entity = ctx.alloc(v._hitEntity_t);

    psx.put(&actor.stats, stats);
    stats.unk957 = if (ctx.chance(2)) 128 else ctx.pick(u8, &.{ 0, 127, 129, 255 });
    stats.statuses = ctx.pick(i32, &.{ 0, -1, 0x7FFF_FFFF, std.math.minInt(i32), 0x0F, 0x10 });

    const params = v.g.vs_main_statusEffectParams();
    for (0..5) |k| {
        params[k][0] = ctx.pick(i32, &.{ 0, -1, 0x0F, std.math.minInt(i32) });
        params[k][1] = ctx.int(i32);
    }

    entity.unk0.targetActor = ctx.range(u8, 0, 15);
    entity.inflictStatuses = ctx.pick(i32, &.{ 0, -1, std.math.minInt(i32), 0x0F });
    v.g.vs_battle_actors()[entity.unk0.targetActor] = actor;

    return .{ ctx.edge(c_int, &.{ 0, 1, 2, 3, 4 }), entity };
}

pub fn classify(args: Args) usize {
    const entity = args[1].?;
    const actor = v.g.vs_battle_actors()[entity.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    return if (stats.unk957 == 128) 1 else 0;
}
