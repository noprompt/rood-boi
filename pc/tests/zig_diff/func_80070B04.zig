//! zig_diff spec: func_80070B04 -> func_80070B04.func_80070B04 (146C.c).
//! Inputs: a D_800F19CC object in the arena with a loop count of 0-23 (edges
//! 0, 1, 22, 23), so the loop runs zero times, once, or to the end of the
//! 23-entry unk29C0 table. Each entry has a hit source around the 0x10 limit
//! (0, 1, 7, 15, 16, 17, 0xFF) and a limb around the -1 test (0, 1, 0x7F,
//! 0x80, 0xFF). All 16 vs_battle_actors point at arena actors with valid
//! stats, so the limb lookup always dereferences live memory. The final copy's
//! target actor is 0, 1 or 0-15: the table has room for 16 entries only.
//! unk4A starts at 0 so that a dropped loop-count store changes the output
//! without giving the mutant a random loop bound.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80070B04));

pub const classes = [_][:0]const u8{ "empty", "limb-lookup", "limb-given", "entity-copy" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;

    const stats = ctx.alloc(v.vs_battle_actor2);
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        psx.put(&actor.stats, stats);
        table[i] = actor;
    }

    d.unk2C00 = if (ctx.chance(3)) ctx.edge(u16, &.{ 0, 1, 22, 23 }) else ctx.range(u16, 0, 23);
    d.unk8.unk4A = 0;
    for (&d.unk29C0) |*e| {
        e.unk9 = ctx.pick(u8, &.{ 0, 1, 7, 15, 16, 17, 0xFF });
        e.unkA = ctx.pick(u8, &.{ 0, 1, 0x7F, 0x80, 0xFF });
    }
    d.unk8.unk4.unk0.targetActor = if (ctx.chance(2)) ctx.edge(u8, &.{ 0, 1, 15 }) else ctx.range(u8, 0, 15);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F19CC().*.?;
    if (d.unk2C00 == 0) return 0;
    const e = d.unk29C0[0];
    if (e.unk9 >= 0x10) return 3;
    return if (e.unkA == 0xFF) 1 else 2;
}
