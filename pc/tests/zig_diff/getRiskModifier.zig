//! zig_diff spec: _getRiskModifier -> get_risk_modifier.getRiskModifier (146C.c).
//! Inputs: a source hit entity whose targetActor selects one of the 16 slots of
//! vs_battle_actors (the table's length; higher indices would read past it), a
//! valid actor in that slot with a stats block whose risk is any u16 (edges at
//! 502-506 around the rate==255 test, and 32767/32768/65535 where an i16 read
//! would go negative). Arguments 0, 2, 3 and 4 are unused by the C.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getRiskModifier));

pub const classes = [_][:0]const u8{ "below-255", "rate-255", "above-255", "risk-high-bit" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.alloc(v.vs_action_t);
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    const source = ctx.alloc(v._hitEntity_t);

    const slot = ctx.range(u8, 0, 15);
    v.g.vs_battle_actors()[slot] = actor;
    psx.put(&actor.stats, stats);
    stats.risk = ctx.pick(u16, &.{ 0, 502, 503, 504, 505, 506, 32767, 32768, 65535 });
    source.unk0.targetActor = slot;

    return .{ @ptrCast(arg0), source, null, ctx.int(c_int), ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const actor = v.g.vs_battle_actors()[args[1].?.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    const risk = stats.risk;
    if (risk >= 32768) return 3;
    if (risk < 503) return 0;
    if (risk > 505) return 2;
    return 1;
}
