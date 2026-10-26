//! zig_diff spec: _removeActorAtIndex -> remove_actor_at_index.removeActorAtIndex (146C.c).
//! Inputs: an index in 0-15 (about 4% at the out-of-range edge 16, and 17, 0xFFFFFFFF,
//! 0x80000000 beyond it), a 16-slot table where each slot is empty or holds a pool actor
//! whose next pointer is valid, the removed actor's allegiance (0x10 or not) and unk40
//! (2 or not), zero to two table predecessors whose next is the removed actor, and an
//! arg1 with or without the sign bit. func_8009CFB0 writes the unk40 the C reads back
//! after it, and func_800E7454 relinks actor->next, which psx_copy reads afterwards.
//! Every callee returns ctx.value draws.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").removeActorAtIndex));

pub const classes = [_][:0]const u8{
    "out-of-range",
    "empty-slot",
    "type-0x10",
    "unk40-2",
    "plain-relinked",
    "plain-unlinked",
};

var pool: [16]*v.vs_battle_actor = undefined;

fn hasPredecessor(table: [*]?*v.vs_battle_actor, t: *v.vs_battle_actor) bool {
    for (0..16) |i| {
        const p = table[i] orelse continue;
        if (psx.get(p.next) == t) return true;
    }
    return false;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();

    for (0..16) |i| {
        const a = ctx.alloc(v.vs_battle_actor);
        pool[i] = a;
        a.allegiance = ctx.pick(u16, &.{ 4, 0x10, 0, 0xFFFF });
        a.unk40 = ctx.pick(i32, &.{ 0, 1, 2, 3, -1 });
    }
    // Every pool actor's next is a valid pool actor.
    for (0..16) |i| psx.put(&pool[i].next, pool[ctx.range(usize, 0, 15)]);

    for (0..16) |i| {
        table[i] = if (ctx.chance(4)) null else pool[i];
    }

    const index: c_uint = if (ctx.chance(10))
        ctx.edge(c_uint, &.{ 16, 16, 17, 0xFFFF_FFFF, 0x8000_0000 })
    else
        ctx.range(c_uint, 0, 15);

    if (index < 16 and ctx.chance(5)) table[index] = null;

    const target: ?*v.vs_battle_actor = if (index < 16) table[index] else null;
    if (target) |t| {
        t.allegiance = if (ctx.chance(3)) 0x10 else ctx.pick(u16, &.{ 0, 4, 0x11, 0xFFFF });
        t.unk40 = ctx.pick(i32, &.{ 2, 2, 0, 1, -1 });
        if (ctx.chance(2)) {
            if (table[ctx.range(usize, 0, 15)]) |p| psx.put(&p.next, t);
        }
        if (ctx.chance(2)) {
            if (table[ctx.range(usize, 0, 15)]) |p| psx.put(&p.next, t);
        }
    }

    const arg1 = ctx.pick(c_int, &.{ 0, 1, -1, std.math.maxInt(c_int), std.math.minInt(c_int) });
    return .{ index, arg1 };
}

pub fn classify(args: Args) usize {
    if (args[0] >= 16) return 0;
    const table = v.g.vs_battle_actors();
    const actor = table[args[0]] orelse return 1;
    if (actor.allegiance == 0x10) return 2;
    if (actor.unk40 == 2) return 3;
    return if (hasPredecessor(table, actor)) 4 else 5;
}

pub const stubs = struct {
    pub fn func_8009CFB0(ctx: *zd.Ctx, index: anytype) c_int {
        const table = v.g.vs_battle_actors();
        const i: usize = @intCast(index);
        if (i < 16) {
            if (table[i]) |a| {
                if (ctx.value(u1) == 1) a.unk40 = ctx.value(i32);
            }
        }
        return ctx.value(c_int);
    }

    pub fn func_800E7454(ctx: *zd.Ctx, actor: anytype) void {
        if (actor) |p| {
            const x: *v.vs_battle_actor = @ptrCast(@alignCast(p));
            if (ctx.value(u2) == 0) psx.put(&x.next, pool[ctx.value(u4)]);
        }
    }
};
