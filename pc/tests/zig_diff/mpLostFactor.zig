//! zig_diff spec: _mpLostFactor -> mp_lost_factor.mpLostFactor (146C.c).
//! Inputs: an arg1 whose target actor (0-15, the table's length) points to an
//! arena actor with a stats block whose maxMP and currentMP are any i16
//! (edges included, so the difference is negative about half the time and
//! equal in about a quarter of the runs), an arg0 action whose hitParams get
//! statFactor 0..31 edges, arg3 and arg4 from -2..5 (all inside the action
//! object), and D_800F19CC pointing at a block whose unk0 is any u32 (0 wraps
//! the "- 1"). The C has no branches or calls; the classes split by the
//! sign of the MP difference and by unk0 == 0.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").mpLostFactor));

pub const classes = [_][:0]const u8{ "mp-over", "mp-spent", "mp-equal", "unk0-zero" };

pub fn prepare(ctx: *zd.Ctx) Args {
    // Room before the action so a negative hitParams index stays in the arena.
    _ = ctx.allocBytes(32, 16);
    const action = ctx.alloc(v.vs_action_t);
    for (&action.hitParams) |*hp| {
        psx.setBits(hp, "statFactor", ctx.pick(u5, &.{ 0, 1, 9, 10, 11, 31 }));
    }

    const hit = ctx.alloc(v._hitEntity_t);
    const hit2 = ctx.alloc(v._hitEntity_t);
    const target = ctx.range(u8, 0, 15);
    hit.unk0.targetActor = target;
    hit2.unk0.targetActor = ctx.int(u8);

    const stats = ctx.alloc(v.vs_battle_actor2);
    const actor = ctx.alloc(v.vs_battle_actor);
    psx.put(&actor.stats, stats);
    v.g.vs_battle_actors()[target] = actor;

    stats.maxMP = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 100 });
    stats.currentMP = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 100 });
    if (ctx.chance(4)) stats.currentMP = stats.maxMP;

    const dg = ctx.alloc(v.D_800F19CC_t);
    dg.unk0 = ctx.pick(u32, &.{ 0, 1, 2, 0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF });
    v.g.D_800F19CC().* = dg;

    const idx = ctx.edge(c_int, &.{ -2, -1, 0, 1, 2, 3, 4, 5 });
    const idx2 = ctx.edge(c_int, &.{ -2, -1, 0, 1, 2, 3, 4, 5 });
    return .{ action, hit, hit2, idx, idx2 };
}

pub fn classify(args: Args) usize {
    const dg = v.g.D_800F19CC().*.?;
    if (dg.unk0 == 0) return 3;
    const actor = v.g.vs_battle_actors()[args[1].?.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    if (stats.currentMP > stats.maxMP) return 0;
    if (stats.currentMP == stats.maxMP) return 2;
    return 1;
}
