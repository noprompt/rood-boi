//! zig_diff spec: _getChainEvasionModifier -> get_chain_evasion_modifier.getChainEvasionModifier (146C.c).
//! Inputs: a target whose actor slot (0-15 of vs_battle_actors) holds an arena actor with random-filled
//! stats; limbs whose chainEvasion is 0, 1, 127, 128, 254 or 255; a targetLimb from 0-5 and out-of-range
//! i8 values (-128..127) that read inside the stats block, with a 16 KB pad before it so negative
//! indices stay in the arena. arg0 and arg1 are null or valid (the C never reads them). The C has no
//! callees. The `rate == 255` branch cannot be reached: (255 - u8) * 100 / 255 is at most 100.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getChainEvasionModifier));

pub const classes = [_][:0]const u8{ "limb-in-range", "limb-out-of-range", "evasion-zero" };

pub fn prepare(ctx: *zd.Ctx) Args {
    // Room before the stats block for negative limb indices (the C reads limbs[-128..127]).
    _ = ctx.allocBytes(16384, 16);
    const stats = ctx.alloc(v.vs_battle_actor2);
    const actor = ctx.alloc(v.vs_battle_actor);
    psx.put(&actor.stats, stats);

    const slot = ctx.range(u8, 0, 15);
    v.g.vs_battle_actors()[slot] = actor;

    for (&stats.limbs) |*l| {
        l.chainEvasion = ctx.pick(u8, &.{ 0, 1, 127, 128, 254, 255 });
    }

    const target = ctx.alloc(v._hitEntity_t);
    target.unk0.targetActor = slot;
    target.unk0.targetLimb = ctx.pick(i8, &.{ 0, 1, 2, 3, 4, 5, -1, 6, 7, -2, 127, -128 });

    const arg0: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    const arg1: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    return .{ arg0, arg1, target, ctx.int(c_int), ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const target = args[2].?;
    const actor = v.g.vs_battle_actors()[target.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    const limb = target.unk0.targetLimb;
    if (limb < 0 or limb > 5) return 1;
    if (stats.limbs[@intCast(limb)].chainEvasion == 0) return 2;
    return 0;
}
