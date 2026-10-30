//! zig_diff spec: _getRisk -> get_risk.getRisk (146C.c).
//! The C has no branches: it reads vs_battle_actors[targetActor] and returns
//! the risk field of that actor's stats block. The inputs fill all 16 table
//! entries with arena actors, each with its own stats block and a risk drawn
//! from the edges (0, 1, 0x7FFF, 0x8000, 0xFFFF) or at random, so a wrong
//! index or field changes the result. targetActor is kept in the table's 16
//! entries; classes split it into the low and high halves.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getRisk));

pub const classes = [_][:0]const u8{ "target-low", "target-high" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        const stats = ctx.alloc(v.vs_battle_actor2);
        stats.risk = ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF });
        psx.put(&actor.stats, stats);
        table[i] = actor;
    }
    const hit = ctx.alloc(v._hitEntity_t);
    hit.unk0.targetActor = ctx.range(u8, 0, 15);
    return .{ null, null, hit, ctx.int(c_int), ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    return if (args[2].?.unk0.targetActor < 8) 0 else 1;
}
