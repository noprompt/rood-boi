//! zig_diff spec: func_8007C218 -> func_8007C218.func_8007C218 (146C.c).
//! Inputs: an index 0-15 into vs_battle_actors (the only entries the C can
//! read), an actor whose stats pointer is null or points at an arena block,
//! currentHP across the signed edges (0 included, so `> 0` sees equal sides),
//! and a nonzero maxHP across positive and negative edges. Small currentHP
//! with a large positive maxHP makes the percentage 0, which the C turns into 1.
//! The C calls nothing, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C218));

pub const classes = [_][:0]const u8{ "null-stats", "dead", "zero-percent", "live" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.range(c_int, 0, 15);
    const actor = ctx.alloc(v.vs_battle_actor);
    v.g.vs_battle_actors()[@intCast(arg0)] = actor;

    const stats = ctx.alloc(v.vs_battle_actor2);
    psx.put(&actor.stats, if (ctx.chance(6)) null else stats);

    stats.currentHP = ctx.pick(i16, &.{ -1, 0, 1, 2, 50, 32767, -32768 });
    const max = ctx.pick(i16, &.{ 1, 2, 100, 101, 200, 999, 32767, -1, -100, -32768 });
    // The C divides by maxHP whenever currentHP > 0: keep it nonzero.
    stats.maxHP = if (max == 0) 1 else max;

    return .{arg0};
}

pub fn classify(args: Args) usize {
    const actor = v.g.vs_battle_actors()[@intCast(args[0])].?;
    const stats = psx.get(actor.stats) orelse return 0;
    if (stats.currentHP <= 0) return 1;
    if (@divTrunc(@as(i32, stats.currentHP) * 100, @as(i32, stats.maxHP)) == 0) return 2;
    return 3;
}
