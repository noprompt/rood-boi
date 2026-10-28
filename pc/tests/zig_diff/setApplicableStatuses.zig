//! zig_diff spec: _setApplicableStatuses -> set_applicable_statuses.setApplicableStatuses (146C.c).
//! Inputs: arg0 in 0..4 (the five status-effect parameter rows), an entity whose
//! target actor is one of the 16 battle-actor slots, and that actor's stats block
//! with unk957 at 128 a quarter of the time. The status words, parameter masks and
//! unk944 come from edge values (0, -1, 1, 0x40, the i32 extremes), so the
//! `statuses & params[3]` test sees zero, nonzero with and without the sign bit,
//! and the remove/inflict masks overlap. The C makes no calls, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setApplicableStatuses));

pub const classes = [_][:0]const u8{
    "unk957-is-128",
    "masked-negative",
    "masked-positive",
    "applied",
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actors = v.g.vs_battle_actors();
    const params = v.g.vs_main_statusEffectParams();
    const entity = ctx.alloc(v._hitEntity_t);
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);

    const edges = [_]i32{ 0, -1, 1, 0x40, std.math.minInt(i32), std.math.maxInt(i32) };
    for (0..5) |row| {
        for (0..4) |k| params[row][k] = ctx.pick(i32, &edges);
    }

    const idx = ctx.range(c_int, 0, 4);
    const row: usize = @intCast(idx);
    params[row][3] = ctx.pick(i32, &edges);

    stats.statuses = ctx.pick(i32, &edges);
    stats.unk944 = ctx.pick(i32, &edges);
    stats.unk957 = if (ctx.chance(4)) 128 else ctx.pick(u8, &.{ 0, 127, 129, 255 });
    psx.put(&actor.stats, stats);

    const target = ctx.range(u8, 0, 15);
    entity.unk0.targetActor = target;
    actors[target] = actor;
    entity.removeStatuses = ctx.int(i32);
    entity.inflictStatuses = ctx.int(i32);

    return .{ idx, entity };
}

pub fn classify(args: Args) usize {
    const actors = v.g.vs_battle_actors();
    const actor = actors[args[1].?.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    if (stats.unk957 == 128) return 0;
    const params = v.g.vs_main_statusEffectParams();
    const hit = stats.statuses & params[@intCast(args[0])][3];
    if (hit != 0) return if (hit < 0) 1 else 2;
    return 3;
}
