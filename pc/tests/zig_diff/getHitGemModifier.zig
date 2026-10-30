//! zig_diff spec: _getHitGemModifier -> get_hit_gem_modifier.getHitGemModifier (146C.c).
//! Inputs: a source and a target entity, each null, busy (unk40 nonzero, with -1 and
//! INT_MIN among the values) or idle (unk40 == 0); an action or null; hitNumber at
//! its edges; and a 16-slot actor table whose entries are arena actors with arena
//! stats. The attack and defense gem buffs are stubs. The attack stub can rewrite
//! table slots and the target's unk40 mid-call, so a port that reads either before
//! the call differs from the C.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getHitGemModifier));

pub const classes = [_][:0]const u8{ "no-source", "source-busy", "no-target", "target-busy", "both-active" };

var pool: [4]*v.vs_battle_actor = undefined;
var ent_target: ?*v._hitEntity_t = null;

pub const stubs = struct {
    pub fn _getAttackGemBuff(ctx: *zd.Ctx, action: anytype, stats: anytype) c_short {
        _ = action;
        _ = stats;
        if (ctx.value(u2) == 0) {
            v.g.vs_battle_actors()[ctx.value(u8) % 16] = pool[ctx.value(u8) % pool.len];
        }
        if (ctx.value(u2) == 0) {
            if (ent_target) |t| t.unk40 = ctx.value(i32);
        }
        return ctx.value(c_short);
    }

    pub fn _getDefenseGemBuff(ctx: *zd.Ctx, action: anytype, stats: anytype, hit: anytype) c_short {
        _ = action;
        _ = stats;
        _ = hit;
        if (ctx.value(u2) == 0) {
            v.g.vs_battle_actors()[ctx.value(u8) % 16] = pool[ctx.value(u8) % pool.len];
        }
        return ctx.value(c_short);
    }
};

fn makeEntity(ctx: *zd.Ctx, null_it: bool) ?*v._hitEntity_t {
    if (null_it) return null;
    const e = ctx.alloc(v._hitEntity_t);
    e.unk0.targetActor = ctx.range(u8, 0, 15);
    e.unk40 = if (ctx.chance(2)) 0 else ctx.pick(i32, &.{ 0, 1, -1, std.math.minInt(i32), std.math.maxInt(i32) });
    return e;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    for (&pool) |*p| {
        const actor = ctx.alloc(v.vs_battle_actor);
        psx.put(&actor.stats, ctx.alloc(v.vs_battle_actor2));
        p.* = actor;
    }
    const table = v.g.vs_battle_actors();
    for (0..16) |i| table[i] = pool[ctx.range(usize, 0, pool.len - 1)];

    const action: ?*v.vs_action_t = if (ctx.chance(3)) null else ctx.alloc(v.vs_action_t);
    const source = makeEntity(ctx, ctx.chance(6));
    const target = makeEntity(ctx, ctx.chance(6));
    ent_target = target;
    const hit = ctx.pick(c_int, &.{ 0, 1, -1, std.math.minInt(c_int), std.math.maxInt(c_int) });
    return .{ action, source, target, hit, ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const source = args[1] orelse return 0;
    if (source.unk40 != 0) return 1;
    const target = args[2] orelse return 2;
    if (target.unk40 != 0) return 3;
    return 4;
}
