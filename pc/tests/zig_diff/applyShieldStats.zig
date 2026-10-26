//! zig_diff spec: vs_battle_applyShieldStats -> apply_shield_stats.applyShieldStats (146C.c).
//! Inputs: a shield intermediate and a UI shield, both in the arena with their
//! random fill. The i8 stat, class and affinity fields are biased to -128, -1, 0
//! and 127, so the sums go negative (the u16 stores wrap) and the index takes the
//! i16 edges. The C has no branches besides its four loops, so the classes sort
//! the inputs by sign of the strength sum, the index and the affinity sum. The
//! memcpy stub really copies, so a dropped or mis-sized copy shows in the bytes.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").applyShieldStats));

pub const classes = [_][:0]const u8{ "strength-sum-negative", "index-negative", "affinity-sum-negative", "other" };

pub const stubs = struct {
    /// memcpy really copies the bytes: the C and the port must agree on the copies.
    pub fn vs_main_memcpy(ctx: *zd.Ctx, dest: anytype, src: anytype, sz: anytype) void {
        _ = ctx;
        const n: usize = @intCast(sz);
        const d: [*]u8 = @ptrCast(dest.?);
        const s: [*]const u8 = @ptrCast(src.?);
        @memcpy(d[0..n], s[0..n]);
    }
};

fn edgeI8(ctx: *zd.Ctx) i8 {
    return ctx.pick(i8, &.{ -128, -1, 0, 127 });
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_battle_uiShield);
    const source = ctx.alloc(v.vs_battle_shieldIntermediate);

    source.index = ctx.pick(i16, &.{ -1, 0, 255, 256, 32767, -32768 });
    source.material = ctx.pick(u8, &.{ 0, 255 });
    source.dropRate = ctx.pick(u8, &.{ 0, 255 });

    source.base.wepId = edgeI8(ctx);
    source.base.strength = edgeI8(ctx);
    source.base.intelligence = edgeI8(ctx);
    source.base.agility = edgeI8(ctx);
    for (&source.base.classes) |*x| x.* = edgeI8(ctx);
    for (&source.base.affinities) |*x| x.* = edgeI8(ctx);
    for (&source.base.types) |*x| x.* = edgeI8(ctx);
    for (&source.gems) |*g| {
        g.strength = edgeI8(ctx);
        g.intelligence = edgeI8(ctx);
        g.agility = edgeI8(ctx);
        for (&g.classes) |*x| x.* = edgeI8(ctx);
        for (&g.affinities) |*x| x.* = edgeI8(ctx);
    }

    return .{ target, source };
}

pub fn classify(args: Args) usize {
    const s = args[1].?;
    const str_sum = @as(i32, s.base.strength) + s.gems[0].strength + s.gems[1].strength + s.gems[2].strength;
    if (str_sum < 0) return 0;
    if (s.index < 0) return 1;
    const aff_sum = @as(i32, s.base.affinities[0]) + s.gems[0].affinities[0] + s.gems[1].affinities[0] + s.gems[2].affinities[0];
    if (aff_sum < 0) return 2;
    return 3;
}
