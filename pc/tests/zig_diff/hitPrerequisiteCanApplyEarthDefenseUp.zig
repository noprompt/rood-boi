//! zig_diff spec: _hitPrerequisiteCanApplyEarthDefenseUp -> hit_prerequisite_can_apply_earth_defense_up.hitPrerequisiteCanApplyEarthDefenseUp (146C.c).
//! Inputs: the effect check (_hitPrerequisiteCanApplyEffect) either applies (nonzero,
//! with and without the sign bit) or not (0, a stub-set result the C tests with ==0).
//! Every vs_battle_actors slot (16) holds a valid actor whose stats carry armor
//! ids chosen by a shared mode: none, one random limb, the shield only, or a mix.
//! Armor ids are 0 or an edge (1, 0x8000, 0xFFFF), so zero tests see nonzero
//! values with and without the sign bit. The index byte is 0..15; the effect stub
//! may rewrite it to another valid slot, which the C then re-reads.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyEarthDefenseUp));

pub const classes = [_][:0]const u8{ "effect-applies", "no-armor", "limb-armor", "shield-armor", "limb-and-shield" };

/// What _hitPrerequisiteCanApplyEffect returns this iteration.
var effect_result: c_int = 0;

fn nonzeroId(ctx: *zd.Ctx) u16 {
    return ctx.edge(u16, &.{ 1, 0x8000, 0xFFFF });
}

fn setArmor(ctx: *zd.Ctx, stats: *v.vs_battle_actor2, mode: u8) void {
    for (&stats.limbs) |*limb| limb.armor.armor.id = 0;
    stats.shield.base.id = 0;
    switch (mode) {
        0 => {},
        1 => stats.limbs[ctx.range(usize, 0, 5)].armor.armor.id = nonzeroId(ctx),
        2 => stats.shield.base.id = nonzeroId(ctx),
        else => {
            for (&stats.limbs) |*limb| {
                if (ctx.chance(2)) limb.armor.armor.id = nonzeroId(ctx);
            }
            if (ctx.chance(2)) stats.shield.base.id = nonzeroId(ctx);
        },
    }
}

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        // The callee may move the slot index the C re-reads after the call.
        if (ctx.value(u1) == 1) arg1[0] = ctx.value(u8) & 15;
        return effect_result;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    effect_result = if (ctx.chance(3))
        ctx.edge(c_int, &.{ 1, -1, 0x100, std.math.minInt(c_int) })
    else
        0;
    const mode = ctx.range(u8, 0, 3);
    const stats = ctx.alloc(v.vs_battle_actor2);
    setArmor(ctx, stats, mode);
    const globals = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        psx.put(&actor.stats, stats);
        globals[i] = actor;
    }
    const index = ctx.alloc(u8);
    index.* = ctx.range(u8, 0, 15);
    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    return .{ action, index };
}

pub fn classify(args: Args) usize {
    if (effect_result != 0) return 0;
    const globals = v.g.vs_battle_actors();
    const actor = globals[args[1][0]].?;
    const stats = psx.get(actor.stats) orelse return 1;
    var limb = false;
    for (stats.limbs) |l| {
        if (l.armor.armor.id != 0) limb = true;
    }
    const shield = stats.shield.base.id != 0;
    if (!limb and !shield) return 1;
    if (limb and !shield) return 2;
    if (!limb and shield) return 3;
    return 4;
}
