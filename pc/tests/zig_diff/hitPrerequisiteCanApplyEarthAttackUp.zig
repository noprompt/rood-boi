//! zig_diff spec: _hitPrerequisiteCanApplyEarthAttackUp -> hit_prerequisite_can_apply_earth_attack_up.hitPrerequisiteCanApplyEarthAttackUp (146C.c).
//! Inputs: a null or arena action (the C never reads it), an index 0-15 into
//! the 16-entry vs_battle_actors table (every entry is an arena actor whose
//! stats block has its own weapon blade id: 0, 1, 0x8000 or 0xFFFF), and an
//! effect result that is 0 (the blade is read) or nonzero with and without the
//! sign bit (the blade is not read). The effect stub returns the prepared
//! result and sometimes rewrites the index byte it was passed, so the C must
//! read *arg1 after the call.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyEarthAttackUp));

pub const classes = [_][:0]const u8{ "effect-nonzero", "blade-zero", "blade-nonzero" };

/// The effect result this iteration's stub returns (set by prepare).
var effect_ret: c_int = 0;

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        // The callee may change the index byte the C reads back after the call.
        if (ctx.value(u2) == 0) arg1.* = ctx.value(u4);
        return effect_ret;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    const arg = ctx.alloc(u8);
    // The table has 16 entries: an index past them would read foreign memory.
    arg.* = ctx.range(u8, 0, 15);
    const actors = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        const stats = ctx.alloc(v.vs_battle_actor2);
        psx.put(&actor.stats, stats);
        stats.weapon.blade.id = if (ctx.chance(2)) 0 else ctx.pick(u16, &.{ 1, 0x8000, 0xFFFF });
        actors[i] = actor;
    }
    effect_ret = if (ctx.chance(4)) ctx.edge(c_int, &.{ 1, -1, 0x7FFF_FFFF, -0x8000_0000 }) else 0;
    return .{ action, arg };
}

pub fn classify(args: Args) usize {
    if (effect_ret != 0) return 0;
    const actor = v.g.vs_battle_actors()[args[1].*].?;
    const stats = psx.get(actor.stats).?;
    return if (stats.weapon.blade.id == 0) 1 else 2;
}
