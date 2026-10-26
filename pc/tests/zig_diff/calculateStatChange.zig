//! zig_diff spec: _calculateStatChange -> calculate_stat_change.calculateStatChange (146C.c).
//! Inputs: an action with two hit parameters whose stat calculators are indices
//! 0-26 (each table entry is a distinct harness function that mixes its index,
//! hit and arg4, so a wrong index or a swapped argument shows in the result),
//! two hit entities (arg2 with unk40 zero about two thirds of the time, arg1
//! with random fields), 16 battle actors each with its own stats block, and a
//! target actor in 0-15 whose stats unk957 is 128 about half the time (the 999
//! path), otherwise an edge or random value. The hit index is 0 or 1.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").calculateStatChange));

pub const classes = [_][:0]const u8{ "unk40-nonzero", "zero-unk40-stat-128", "zero-unk40-other-stat" };

/// The stat calculators: a pure function of its index, hit and arg4.
fn Calc(comptime k: usize) type {
    return struct {
        fn f(a: ?*anyopaque, b: ?*anyopaque, c_arg: ?*anyopaque, hit: c_int, arg4: c_int) callconv(.c) c_short {
            _ = .{ a, b, c_arg };
            return @truncate(@as(c_int, k) *% 1000 +% hit *% 7 -% arg4);
        }
    };
}

const calc_table: [27]*const anyopaque = blk: {
    var t: [27]*const anyopaque = undefined;
    for (0..27) |i| t[i] = @ptrCast(&Calc(i).f);
    break :blk t;
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // Table of stat calculators: every entry a distinct, callable function.
    for (calc_table, 0..) |p, k| v.g._statCalculators()[k] = p;

    // The action: both hit parameters name a calculator in the table.
    const action = ctx.alloc(v.vs_action_t);
    for (0..2) |h| psx.setBits(&action.hitParams[h], "statCalculator", ctx.range(u6, 0, 26));

    const arg1 = ctx.alloc(v._hitEntity_t);
    const arg2 = ctx.alloc(v._hitEntity_t);
    arg2.unk40 = if (ctx.chance(3)) ctx.pick(i32, &.{ 1, -1, 256 }) else 0;
    const target = ctx.range(u8, 0, 15);
    arg2.unk0.targetActor = target;

    // Battle actors: each with its own stats block, so a wrong index shows.
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        const actor = ctx.alloc(v.vs_battle_actor);
        const stats = ctx.alloc(v.vs_battle_actor2);
        psx.put(&actor.stats, stats);
        stats.unk957 = ctx.pick(u8, &.{ 128, 127, 129, 0, 255 });
        v.g.vs_battle_actors()[i] = actor;
    }
    // The targeted actor's stats are 128 about half the time.
    const tact = v.g.vs_battle_actors()[target].?;
    if (ctx.chance(2)) psx.get(tact.stats).?.unk957 = 128;

    const hit: c_int = ctx.range(c_int, 0, 1);
    const arg4: c_int = ctx.int(c_int);
    return .{ action, arg1, arg2, hit, arg4 };
}

pub fn classify(args: Args) usize {
    const arg2 = args[2].?;
    if (arg2.unk40 != 0) return 0;
    const actor = v.g.vs_battle_actors()[arg2.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    return if (stats.unk957 == 128) 1 else 2;
}
