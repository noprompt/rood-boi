//! zig_diff spec: _removeActor -> remove_actor.removeActor (146C.c).
//! Inputs: an actor whose id is 0, 1, -1, an extreme or random (both signs),
//! and the 16-slot table of vs_battle_actors. Each slot is null or an arena
//! actor whose next points to the actor, to another object or to null. A
//! match is placed at a slot 0-15 (edges 0, 1, 14, 15 and random), either by
//! an arena slot or by the actor linking to itself, and sometimes a second
//! match follows it (the first one wins). Without a match the loop runs all
//! 16 iterations, so `i < 16` sees equal sides at its exit.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").removeActor));

pub const classes = [_][:0]const u8{ "id-zero", "no-match", "match", "self-link", "match-slot-15" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const other = ctx.alloc(v.vs_battle_actor);
    var pool: [16]*v.vs_battle_actor = undefined;
    for (&pool) |*p| p.* = ctx.alloc(v.vs_battle_actor);
    const table = v.g.vs_battle_actors();
    const nil: ?*v.vs_battle_actor = null;

    actor.id = ctx.pick(i32, &.{ 1, -1, std.math.minInt(i32), std.math.maxInt(i32), 0x4000_0000 });
    if (ctx.chance(6)) actor.id = 0;

    // First pass: no slot points at the actor.
    for (0..16) |i| {
        table[i] = if (ctx.chance(4)) nil else pool[i];
        const link: ?*v.vs_battle_actor = if (ctx.chance(3)) null else if (ctx.chance(2)) other else pool[(i + 1) % 16];
        psx.put(&pool[i].next, link);
    }
    const first: ?*v.vs_battle_actor = if (ctx.chance(3)) null else other;
    psx.put(&actor.next, first);

    // A match in most runs: at slot k, sometimes the actor itself, sometimes a
    // second match after it (the C returns at the first).
    if (!ctx.chance(5)) {
        const k: usize = if (ctx.chance(2)) ctx.edge(usize, &.{ 0, 1, 14, 15 }) else ctx.range(usize, 0, 15);
        if (ctx.chance(6)) {
            table[k] = actor;
            psx.put(&actor.next, actor);
        } else {
            table[k] = pool[k];
            psx.put(&pool[k].next, actor);
        }
        if (k < 15 and ctx.chance(4)) {
            const j = ctx.range(usize, k + 1, 15);
            table[j] = pool[j];
            psx.put(&pool[j].next, actor);
        }
    }
    return .{actor};
}

pub fn classify(args: Args) usize {
    const actor = args[0].?;
    if (actor.id == 0) return 0;
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const slot = table[i] orelse continue;
        if (psx.get(slot.next) == actor) {
            if (i == 15) return 4;
            return if (slot == actor) 3 else 2;
        }
    }
    return 1;
}
