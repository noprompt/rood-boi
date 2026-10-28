//! zig_diff spec: _hitPrerequisiteCanApplyEquipDown -> hit_prerequisite_can_apply_equip_down.hitPrerequisiteCanApplyEquipDown (146C.c).
//! Inputs: a battle actor in the arena whose stats pointer leads to a random
//! vs_battle_actor2, with the table entry at a random index 0-15 set to it. Each
//! limb armor, the shield base and the weapon blade get an id that is zero or
//! an edge (1, 0x7FFF, 0x8000, 0xFFFF), or the whole block is bare. The effect
//! hook returns zero or nonzero, and sometimes repoints the actor's stats at
//! another block, so a port that reads the stats before the call diverges.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyEquipDown));

pub const classes = [_][:0]const u8{ "bare", "limb", "shield-only", "weapon-only" };

/// The second stats block the effect hook may switch the actor to.
var other: *v.vs_battle_actor2 = undefined;

fn equipId(ctx: *zd.Ctx, bare: bool) u16 {
    if (bare or ctx.chance(2)) return 0;
    return ctx.pick(u16, &.{ 1, 0x8000, 0xFFFF, 0x7FFF });
}

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        const proceed = ctx.value(u2) == 0;
        if (ctx.value(u2) == 0) {
            // The C re-reads the stats pointer after the call.
            const actor = v.g.vs_battle_actors()[arg1[0]].?;
            psx.put(&actor.stats, other);
        }
        if (proceed) return 0;
        return ctx.value(c_int) | 1;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    other = ctx.alloc(v.vs_battle_actor2);
    const bare = ctx.chance(3);
    for (&stats.limbs) |*limb| limb.armor.armor.id = equipId(ctx, bare);
    stats.shield.base.id = equipId(ctx, bare);
    stats.weapon.blade.id = equipId(ctx, bare);
    psx.put(&actor.stats, stats);

    const index: u8 = ctx.range(u8, 0, 15);
    v.g.vs_battle_actors()[index] = actor;
    const index_ptr = ctx.allocBytes(1, 1);
    index_ptr[0] = index;

    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    return .{ action, index_ptr };
}

pub fn classify(args: Args) usize {
    const actor = v.g.vs_battle_actors()[args[1][0]].?;
    const stats = psx.get(actor.stats).?;
    var limb = false;
    for (stats.limbs) |l| {
        if (l.armor.armor.id != 0) limb = true;
    }
    const shield = stats.shield.base.id != 0;
    const weapon = stats.weapon.blade.id != 0;
    if (!limb and !shield and !weapon) return 0;
    if (limb) return 1;
    if (shield) return 2;
    return 3;
}
