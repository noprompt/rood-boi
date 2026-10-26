//! zig_diff spec: _calculateShieldClassAffinity -> calculate_shield_class_affinity.calculateShieldClassAffinity (146C.c).
//! Inputs: an arena vs_battle_actor2 with its shield's base, gem and unk134 arrays
//! random (any i8 classes and affinities, any i16 unk134), so the four-term sums
//! and the affinity[0] sums with unk134 overflow the short temporary. About a third
//! of the runs make every term small so the sums stay in range, and some runs pin
//! unk134 and one base affinity to the i8/i16 extremes. The function makes no
//! calls and reads no globals, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").calculateShieldClassAffinity));

pub const classes = [_][:0]const u8{ "affinity-sum-in-i8", "affinity-sum-overflows-i8" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor2);
    const sh = &actor.shield;
    if (ctx.chance(3)) {
        for (&sh.base.classes) |*x| x.* = ctx.range(i8, -4, 4);
        for (&sh.base.affinities) |*x| x.* = ctx.range(i8, -4, 4);
        for (&sh.unk134) |*x| x.* = ctx.range(i16, -4, 4);
        for (0..3) |g| {
            for (&sh.gems[g].classes) |*x| x.* = ctx.range(i8, -4, 4);
            for (&sh.gems[g].affinities) |*x| x.* = ctx.range(i8, -4, 4);
        }
    }
    if (ctx.chance(4)) {
        for (&sh.unk134) |*x| x.* = ctx.pick(i16, &.{ 32767, -32768, -1, 0 });
    }
    if (ctx.chance(4)) {
        sh.base.affinities[ctx.range(usize, 0, 7)] = ctx.pick(i8, &.{ 127, -128 });
    }
    return .{actor};
}

pub fn classify(args: Args) usize {
    const sh = &args[0].?.shield;
    const sum: i32 = @as(i32, sh.base.affinities[0]) + sh.gems[0].affinities[0] + sh.gems[1].affinities[0] + sh.gems[2].affinities[0];
    return if (sum >= -128 and sum <= 127) 0 else 1;
}
