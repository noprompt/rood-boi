//! zig_diff spec: func_8006F630 -> func_8006F630.func_8006F630 (146C.c).
//! Inputs: three arena objects (the effect/action record `arg1` names with
//! a random 7-bit effect on its hitParams[0], biased to the 0x3A/0x3E,
//! 0x3B, 0x3F and default cases; the random hit record `arg2`; a
//! destination `arg0` with random bytes). `arg2`'s actorId selects one
//! `vs_battle_actors` entry, set by prepare to an arena actor whose stats
//! carry a random enemyClass. The C makes no calls, so no stubs are needed.
//! The action index stays in 0..255 (the table's room), and no argument is
//! null because the C never tests for null.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006F630));

pub const classes = [_][:0]const u8{ "effect-3A-3E", "effect-3B", "effect-3F", "effect-default" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const t1 = ctx.alloc(v.func_8006F630_t1);
    const t2 = ctx.alloc(v.func_8006F630_t2);
    const t3 = ctx.alloc(v.func_8006F630_t3);

    const actionId = ctx.range(u16, 0, 255);
    t2.actionId = actionId;
    t2.unk2 = ctx.int(u8);
    t2.unk3 = ctx.int(u8);

    const effect: u7 = if (ctx.chance(2))
        ctx.int(u7)
    else
        ctx.edge(u7, &.{ 0x3A, 0x3E, 0x3B, 0x3F, 0x3C, 0x39, 0x00, 0x7F, 0x40 });
    psx.setBits(&v.g.actions()[actionId].hitParams[0], "effect", effect);

    psx.setBits(t3, "actorId", ctx.range(u4, 0, 15));
    const id = psx.getBits(t3, "actorId");

    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    psx.put(&actor.stats, stats);
    psx.setBits(stats, "enemyClass", ctx.int(u3));
    v.g.vs_battle_actors()[id] = actor;

    return .{ t1, t2, t3 };
}

pub fn classify(args: Args) usize {
    const effect = psx.getBits(&v.g.actions()[args[1].?.actionId].hitParams[0], "effect");
    return switch (effect) {
        0x3A, 0x3E => 0,
        0x3B => 1,
        0x3F => 2,
        else => 3,
    };
}
