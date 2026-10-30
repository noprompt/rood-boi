//! zig_diff spec: _hitPrerequisiteCanApplyWaterAttackUp -> hit_prerequisite_can_apply_water_attack_up.hitPrerequisiteCanApplyWaterAttackUp (146C.c).
//! Inputs: an action pointer (null or an arena object, which the C ignores),
//! and an actor index byte in 0..15. All 16 entries of vs_battle_actors point
//! to arena actors whose stats (one shared block) carry a random blade id,
//! drawn from edges 0, 1, 0xFFFF and 0x8000 half the time. The stub of
//! _hitPrerequisiteCanApplyEffect returns 0 about 37% of the time (the C's
//! `== 0` test), any other i32 otherwise, and may move the actor index and
//! rewrite the blade id, which the C reads again after the call.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyWaterAttackUp));

pub const classes = [_][:0]const u8{ "blade-nonzero", "blade-zero" };

var actors: [16]*v.vs_battle_actor = undefined;
var stats_obj: *v.vs_battle_actor2 = undefined;

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        // The callee may move the actor index the C reads again after the call.
        if (ctx.value(u8) < 64) arg1.* = ctx.value(u8) & 15;
        // The callee may rewrite the blade the C tests after the call.
        if (ctx.value(u8) < 48) stats_obj.weapon.blade.id = ctx.value(u16);
        if (ctx.value(u8) < 96) return 0;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    stats_obj = ctx.alloc(v.vs_battle_actor2);
    stats_obj.weapon.blade.id = ctx.pick(u16, &.{ 0, 1, 0xFFFF, 0x8000 });
    const tbl = v.g.vs_battle_actors();
    for (0..16) |i| {
        const a = ctx.alloc(v.vs_battle_actor);
        actors[i] = a;
        psx.put(&a.stats, stats_obj);
        tbl[i] = a;
    }
    const idx = ctx.alloc(u8);
    idx.* = ctx.range(u8, 0, 15);
    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    return .{ action, idx };
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (stats_obj.weapon.blade.id != 0) 0 else 1;
}
