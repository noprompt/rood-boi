//! zig_diff spec: _hitPrerequisiteCanApplyWaterDefenseUp -> hit_prerequisite_can_apply_water_defense_up.hitPrerequisiteCanApplyWaterDefenseUp (146C.c).
//! Inputs: an optional action (unused by the C), an index byte 0..15 into
//! vs_battle_actors (every entry points at one actor, so any index the C
//! reads or the callee writes stays valid), and a stats block whose six limb
//! armor ids and shield base id are zero or nonzero in several arrangements
//! (only the last limb, only the shield, a middle limb, both, every limb).
//! The stub of _hitPrerequisiteCanApplyEffect returns 0 or nonzero and may
//! rewrite the index byte, so the C must re-read *arg1 after the call.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyWaterDefenseUp));

pub const classes = [_][:0]const u8{ "no-armor", "last-limb-only", "shield-only", "both", "limb-only" };

const nonzero = [_]u16{ 1, 2, 0x8000, 0xFFFF };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        // The callee may change the index byte; the C must read it back.
        if (ctx.value(u1) == 1) arg1[0] = ctx.value(u8) & 15;
        if (ctx.value(u8) < 128) return 0;
        return ctx.value(c_int) | 1;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    psx.put(&actor.stats, stats);

    // Every table entry is valid, so any index the stub writes is safe.
    const table = v.g.vs_battle_actors();
    for (0..16) |i| table[i] = actor;

    const index: *u8 = ctx.alloc(u8);
    index.* = ctx.range(u8, 0, 15);

    for (&stats.limbs) |*limb| limb.armor.armor.id = 0;
    stats.shield.base.id = 0;

    switch (ctx.range(u8, 0, 5)) {
        0 => {},
        1 => stats.limbs[5].armor.armor.id = ctx.edge(u16, &nonzero),
        2 => stats.shield.base.id = ctx.edge(u16, &nonzero),
        3 => stats.limbs[ctx.range(usize, 0, 4)].armor.armor.id = ctx.edge(u16, &nonzero),
        4 => {
            stats.limbs[ctx.range(usize, 0, 5)].armor.armor.id = ctx.edge(u16, &nonzero);
            stats.shield.base.id = ctx.edge(u16, &nonzero);
        },
        else => {
            for (&stats.limbs) |*limb| {
                if (ctx.chance(2)) limb.armor.armor.id = ctx.edge(u16, &nonzero);
            }
        },
    }

    return .{ action, @ptrCast(index) };
}

pub fn classify(args: Args) usize {
    const actor = v.g.vs_battle_actors()[args[1][0]].?;
    const stats = psx.get(actor.stats).?;
    var low = false;
    for (stats.limbs[0..5]) |l| {
        if (l.armor.armor.id != 0) low = true;
    }
    const last = stats.limbs[5].armor.armor.id != 0;
    const shield = stats.shield.base.id != 0;
    if (low and shield) return 3;
    if (shield) return 2;
    if (low) return 4;
    if (last) return 1;
    return 0;
}
