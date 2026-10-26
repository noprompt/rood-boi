//! zig_diff spec: func_80080000 -> func_80080000.func_80080000 (146C.c).
//! Inputs: a random vs_action_t whose unk2_4 selects each switch arm (0-15),
//! a _hitEntity_t with a targetActor in 0-15 (its table entry points at an
//! arena actor whose stats are always present) and a targetLimb in 0-7 (6 and
//! 7 are past the six limbs but inside the arrays the C indexes), and a stats
//! block whose six limbs have maxHp zero or any i16 (signed, sign bit both
//! ways) so the alive count runs from 0 to 6. baseValue is a short from the
//! edges (0, +-1, 6, 7, 100, the i16 extremes) and random, so the division
//! and the splash product see negative and wrapping values. The C calls
//! nothing external, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80080000));

pub const classes = [_][:0]const u8{ "limbs-none-alive", "limbs-some-alive", "splash", "single", "no-case" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const entity = ctx.alloc(v._hitEntity_t);
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);

    // Every switch arm, including the ones with no case (9, 10, 13, 15).
    psx.setBits(action, "unk2_4", ctx.range(u4, 0, 15));

    entity.unk0.targetActor = ctx.range(u8, 0, 15);
    entity.unk0.targetLimb = ctx.range(i8, 0, 7);

    // The C always dereferences the stats: they are always present.
    psx.put(&actor.stats, stats);
    v.g.vs_battle_actors()[entity.unk0.targetActor] = actor;

    // Limb maxHp: sometimes all zero (the count stays 0), otherwise mostly
    // nonzero, with zero and negative values among them.
    const none_alive = ctx.chance(5);
    for (&stats.limbs) |*limb| {
        limb.maxHp = if (none_alive or ctx.chance(3))
            0
        else
            ctx.pick(i16, &.{ 1, -1, 32767, -32768, 6 });
    }

    const base = ctx.pick(i16, &.{ 0, 1, -1, 6, 7, 100, 32767, -32768 });
    return .{ action, entity, base };
}

pub fn classify(args: Args) usize {
    const action = args[0].?;
    const entity = args[1].?;
    const actor = v.g.vs_battle_actors()[entity.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    const sel = psx.getBits(action, "unk2_4");
    switch (sel) {
        0...4 => {
            for (stats.limbs) |limb| {
                if (limb.maxHp != 0) return 1;
            }
            return 0;
        },
        5, 7, 14 => return 2,
        6, 8, 11, 12 => return 3,
        else => return 4,
    }
}
