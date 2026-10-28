//! zig_diff spec: func_8007C28C -> func_8007C28C.func_8007C28C (146C.c).
//! Inputs: an index 0-15 into vs_battle_actors, which is either NULL, an actor
//! whose stats pointer is NULL, or an actor with a random stats block (its
//! maxHP, maxMP and limb maxHp drawn from edge values, the rest random bytes).
//! The callee func_80086754 is a recording stub that sometimes rewrites the
//! stats block and D_800F5160, as the real callee may.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C28C));

pub const classes = [_][:0]const u8{ "no-actor", "no-stats", "stats" };

pub const stubs = struct {
    pub fn func_80086754(ctx: *zd.Ctx, a: anytype, p: anytype) void {
        _ = a;
        const s: *v.vs_battle_actor2 = @ptrCast(@alignCast(p));
        if (ctx.value(u1) == 1) s.currentHP = ctx.value(i16);
        if (ctx.value(u2) == 0) v.g.D_800F5160().* = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const idx: u4 = ctx.range(u4, 0, 15);
    const actors = v.g.vs_battle_actors();
    if (ctx.chance(5)) {
        actors[idx] = null;
    } else {
        const actor = ctx.alloc(v.vs_battle_actor);
        const stats = ctx.alloc(v.vs_battle_actor2);
        stats.maxHP = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
        stats.maxMP = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
        for (&stats.limbs) |*limb| {
            limb.maxHp = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
        }
        psx.put(&actor.stats, if (ctx.chance(6)) null else stats);
        actors[idx] = actor;
    }
    return .{@as(c_int, idx)};
}

pub fn classify(args: Args) usize {
    const actor = v.g.vs_battle_actors()[@intCast(args[0])] orelse return 0;
    _ = psx.get(actor.stats) orelse return 1;
    return 2;
}
