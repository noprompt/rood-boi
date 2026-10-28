//! zig_diff spec: _hitPrerequisiteCanApplyFireDefenseUp -> hit_prerequisite_can_apply_fire_defense_up.hitPrerequisiteCanApplyFireDefenseUp (146C.c).
//! Inputs: the action (null or an arena block, unused by the C) and an index byte 0..15 into
//! vs_battle_actors, whose 16 entries prepare fills with arena actors. Each actor's stats
//! block has random limb and shield armor ids (0, 1, 0x8000, 0xFFFF) under a random limb mask,
//! so the loop sees no armor, a single limb (the last one included), several limbs, the shield
//! alone, or shield and limbs. The _hitPrerequisiteCanApplyEffect stub returns a value set by
//! prepare (0 or nonzero) and sometimes overwrites the index byte it was passed, which the C
//! reads back for the table lookup.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyFireDefenseUp));

pub const classes = [_][:0]const u8{
    "effect-nonzero",
    "no-armor",
    "limb-armor",
    "shield-only",
    "shield-and-limbs",
    "last-limb-only",
};

/// What the effect stub returns in this iteration (set by prepare).
var effect_result: c_int = 0;

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        if (ctx.value(u2) == 0) {
            // The callee may change the index byte the C reads back afterwards.
            const p: *u8 = @ptrCast(arg1);
            p.* = ctx.value(u4);
        }
        return effect_result;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    for (0..16) |k| {
        const actor = ctx.alloc(v.vs_battle_actor);
        const st = ctx.alloc(v.vs_battle_actor2);
        psx.put(&actor.stats, st);
        table[k] = actor;

        const limb_mask: u8 = if (ctx.chance(3)) 0 else ctx.range(u8, 0, 63);
        for (&st.limbs, 0..) |*limb, i| {
            const bit: u3 = @intCast(i);
            limb.armor.armor.id = if (((limb_mask >> bit) & 1) == 1)
                ctx.pick(u16, &.{ 1, 0x8000, 0xFFFF })
            else
                0;
        }
        st.shield.base.id = if (ctx.chance(3)) 0 else ctx.pick(u16, &.{ 1, 0x8000, 0xFFFF });
    }

    const idx = ctx.alloc(u8);
    idx.* = ctx.range(u8, 0, 15);
    effect_result = if (ctx.chance(3)) 0 else ctx.edge(c_int, &.{ 1, -1, 256 });
    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    return .{ action, idx };
}

pub fn classify(args: Args) usize {
    if (effect_result != 0) return 0;
    const actor = v.g.vs_battle_actors()[args[1][0]].?;
    const stats = psx.get(actor.stats).?;
    var limbs: u8 = 0;
    for (stats.limbs, 0..) |limb, i| {
        if (limb.armor.armor.id != 0) limbs |= @as(u8, 1) << @as(u3, @intCast(i));
    }
    const shield = stats.shield.base.id != 0;
    if (shield) return if (limbs == 0) 3 else 4;
    if (limbs == 0) return 1;
    return if (limbs == 32) 5 else 2;
}
