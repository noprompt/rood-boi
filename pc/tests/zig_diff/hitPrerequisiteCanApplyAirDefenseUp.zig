//! zig_diff spec: _hitPrerequisiteCanApplyAirDefenseUp -> hit_prerequisite_can_apply_air_defense_up.hitPrerequisiteCanApplyAirDefenseUp (146C.c).
//! Inputs: sixteen actors in `vs_battle_actors`, each with its own arena stats block
//! whose six limb armor ids and shield base id are zero or one of the edges 1, 0x8000,
//! 0xFFFF (so the id tests see both signs). The selected index (0-15) is what the
//! effect check may rewrite, so the C must read `*arg1` after the call. The effect
//! check returns 0 about half the time and a nonzero value otherwise.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyAirDefenseUp));

pub const classes = [_][:0]const u8{ "no-armor", "limb-armor", "shield-armor", "limb-and-shield" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        // The real effect check may rewrite the actor index the C reads afterwards.
        if (ctx.value(u1) == 1) arg1.* = ctx.value(u8) & 15;
        if (ctx.value(u8) < 128) return 0;
        const r = ctx.value(c_int);
        return if (r == 0) 1 else r;
    }
};

fn setArmor(ctx: *zd.Ctx, stats: *v.vs_battle_actor2) void {
    const limbs_armed = ctx.chance(2);
    const shield_armed = ctx.chance(2);
    for (&stats.limbs) |*limb| {
        limb.armor.armor.id = if (limbs_armed and ctx.chance(3))
            ctx.edge(u16, &.{ 1, 0x8000, 0xFFFF })
        else
            0;
    }
    stats.shield.base.id = if (shield_armed) ctx.edge(u16, &.{ 1, 0x8000, 0xFFFF }) else 0;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    var k: usize = 0;
    while (k < 16) : (k += 1) {
        const actor = ctx.alloc(v.vs_battle_actor);
        const stats = ctx.alloc(v.vs_battle_actor2);
        psx.put(&actor.stats, stats);
        table[k] = actor;
        setArmor(ctx, stats);
    }
    const idx = ctx.alloc(u8);
    idx.* = ctx.range(u8, 0, 15);
    const action = ctx.alloc(v.vs_action_t);
    return .{ action, idx };
}

pub fn classify(args: Args) usize {
    const actor = v.g.vs_battle_actors()[args[1][0]].?;
    const stats = psx.get(actor.stats).?;
    var limb = false;
    for (stats.limbs) |l| {
        if (l.armor.armor.id != 0) limb = true;
    }
    const shield = stats.shield.base.id != 0;
    if (limb and shield) return 3;
    if (limb) return 1;
    if (shield) return 2;
    return 0;
}
