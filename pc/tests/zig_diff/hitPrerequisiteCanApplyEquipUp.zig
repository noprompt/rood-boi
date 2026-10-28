//! zig_diff spec: _hitPrerequisiteCanApplyEquipUp -> hit_prerequisite_can_apply_equip_up.hitPrerequisiteCanApplyEquipUp (146C.c).
//! Inputs: the effect check's result (zero, 1, -1, 0x40 and minInt, since the C
//! tests `!= 0`), the callee sometimes rewriting the index byte (the C re-reads
//! it, and the index is masked to the sixteen table slots), and sixteen actors in
//! vs_battle_actors, each with its own stats. Limb, shield-base and weapon-blade
//! ids are zero or nonzero (edges 1, 0x100, 0x8000, 0xFFFF), with some actors
//! all-zero. Gems and grips stay random, so the shield and weapon checks differ
//! from a port that tests them.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyEquipUp));

pub const classes = [_][:0]const u8{ "effect-blocked", "no-equipment", "limb", "shield", "weapon" };

/// The value the effect check returns in this iteration.
var effect_ret: c_int = 0;

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        const q: [*c]u8 = arg1;
        // The callee may rewrite the index byte the C re-reads (kept inside the table).
        if (ctx.value(u1) == 1) q[0] = ctx.value(u8) & 15;
        return effect_ret;
    }
};

fn equipId(ctx: *zd.Ctx, all_zero: bool) u16 {
    if (all_zero or ctx.chance(2)) return 0;
    return ctx.pick(u16, &.{ 1, 0x100, 0x8000, 0xFFFF });
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const tbl = v.g.vs_battle_actors();
    const all_zero = ctx.chance(4);
    for (0..16) |k| {
        const actor = ctx.alloc(v.vs_battle_actor);
        const stats = ctx.alloc(v.vs_battle_actor2);
        psx.put(&actor.stats, stats);
        tbl[k] = actor;
        for (&stats.limbs) |*l| l.armor.armor.id = equipId(ctx, all_zero);
        stats.shield.base.id = equipId(ctx, all_zero);
        stats.weapon.blade.id = equipId(ctx, all_zero);
    }

    effect_ret = ctx.edge(c_int, &.{ 0, 0, 1, -1, 0x40, std.math.minInt(c_int) });

    const idx: u8 = ctx.range(u8, 0, 15);
    const p = ctx.alloc(u8);
    p.* = idx;
    const act: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    return .{ act, p };
}

pub fn classify(args: Args) usize {
    if (effect_ret != 0) return 0;
    const actor = v.g.vs_battle_actors()[args[1][0]].?;
    const stats = psx.get(actor.stats).?;
    for (stats.limbs) |l| {
        if (l.armor.armor.id != 0) return 2;
    }
    if (stats.shield.base.id != 0) return 3;
    if (stats.weapon.blade.id != 0) return 4;
    return 1;
}
