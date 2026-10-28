//! zig_diff spec: _getEnemyClass -> get_enemy_class.getEnemyClass (146C.c).
//! Inputs: a one-byte index 0..15, the table's length, and a table of sixteen
//! valid actors in the arena. Each actor has its own stats block (a
//! vs_battle_actor2) with a random 3-bit enemyClass, so every class 0-7 occurs
//! for every index. Every entry is valid, so a port that reads a neighbouring
//! entry gives a different class. The C has no branch, no call and no
//! comparison: the spec covers the index read, the stats pointer read and the
//! 3-bit field read.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getEnemyClass));

pub const classes = [_][:0]const u8{
    "class-0", "class-1", "class-2", "class-3",
    "class-4", "class-5", "class-6", "class-7",
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        const stats = ctx.alloc(v.vs_battle_actor2);
        psx.put(&actor.stats, stats);
        psx.setBits(stats, "enemyClass", ctx.int(u3));
        table[i] = actor;
    }
    const idx = ctx.allocBytes(1, 1);
    idx[0] = ctx.range(u8, 0, 15);
    return .{idx};
}

pub fn classify(args: Args) usize {
    const actor = v.g.vs_battle_actors()[args[0][0]].?;
    const stats = psx.get(actor.stats).?;
    return @as(usize, psx.getBits(stats, "enemyClass"));
}
