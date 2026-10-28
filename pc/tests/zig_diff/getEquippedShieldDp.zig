//! zig_diff spec: _getEquippedShieldDp -> get_equipped_shield_dp.getEquippedShieldDp (146C.c).
//! Inputs: a hit entity whose targetActor selects one of the 16 entries of
//! vs_battle_actors (every entry is a valid arena actor with its own stats
//! block, so a wrong index picks different data), a random shield currentPp
//! with the edges 0, 1, 0x7FFF, 0x8000 and 0xFFFF (the top bit decides the
//! sign of the short return), and random unused arguments.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getEquippedShieldDp));

pub const classes = [_][:0]const u8{ "pp-below-0x8000", "pp-top-bit-set" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        const stats = ctx.alloc(v.vs_battle_actor2);
        psx.put(&actor.stats, stats);
        stats.shield.currentPp = ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF });
        table[i] = actor;
    }
    const hit = ctx.alloc(v._hitEntity_t);
    hit.unk0.targetActor = if (ctx.chance(2))
        ctx.edge(u8, &.{ 0, 15 })
    else
        ctx.range(u8, 0, 15);
    const arg0 = ctx.alloc(v.vs_action_t);
    const arg2 = ctx.alloc(v._hitEntity_t);
    return .{ arg0, hit, arg2, ctx.int(c_int), ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const hit = args[1].?;
    const actor = v.g.vs_battle_actors()[hit.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    return if (stats.shield.currentPp < 0x8000) 0 else 1;
}
