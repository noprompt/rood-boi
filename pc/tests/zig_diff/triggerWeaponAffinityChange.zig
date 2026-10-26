//! zig_diff spec: _triggerWeaponAffinityChange -> trigger_weapon_affinity_change.triggerWeaponAffinityChange (146C.c).
//! Inputs: an action whose hitParams[0].affinity is 0 (the argument decides)
//! or 1-7 (it decides, 0-6 after the -1), an equipment block whose eight
//! affinities are either edge values (-128, -101, -100, -99, 0, 99, 100, 101, 127)
//! or a band (-100..-69) where ((a + 100) / 4) + 20 lands in 20..27, with the
//! target often at 99-101 so the cap and rejection comparisons see equal sides.
//! The getRand stub returns a value in 20..27 half the time, so the
//! `((a + 100) / 4) + 20 >= randVal` compares see exact equality often, and
//! `70 - ((a + 100) / 4) < randVal` is false for the banded values. The
//! random-or-edge suppressNotification and arg3 cover both notify paths, and
//! the argument affinity is in 0..6. The C has no null tests, so both
//! pointers are always valid.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").triggerWeaponAffinityChange));

pub const classes = [_][:0]const u8{ "capped", "target-zero", "target-nonzero-notify", "target-nonzero-silent" };

pub const stubs = struct {
    pub fn vs_main_getRand(ctx: *zd.Ctx, n: anytype) c_int {
        _ = n;
        if (ctx.value(u1) == 1) return @intCast(ctx.value(u8));
        return @as(c_int, 20 + ctx.value(u8) % 8);
    }

    pub fn func_80096768(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) void {
        _ = ctx;
        _ = a;
        _ = b;
        _ = c;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const equipment = ctx.alloc(v.vs_battle_uiEquipment);

    const hit: u3 = if (ctx.chance(3)) 0 else ctx.range(u3, 1, 7);
    psx.setBits(&action.hitParams[0], "affinity", hit);

    const affinity: c_int = if (hit != 0) ctx.int(c_int) else ctx.range(c_int, 0, 6);
    const target: usize = if (hit != 0) @as(usize, hit - 1) else @as(usize, @intCast(affinity));

    const edges = [_]i8{ -128, -101, -100, -99, 0, 99, 100, 101, 127 };
    for (&equipment.affinities) |*a| {
        a.* = if (ctx.chance(2)) ctx.range(i8, -100, -69) else ctx.pick(i8, &edges);
    }
    if (ctx.chance(3)) equipment.affinities[target] = ctx.edge(i8, &.{ 99, 100, 101, -100, -101 });

    const arg3: c_int = ctx.pick(c_int, &.{ 0, 1, -1 });
    const suppress: c_int = ctx.pick(c_int, &.{ 0, 1, -1 });

    return .{ action, equipment, affinity, arg3, suppress };
}

pub fn classify(args: Args) usize {
    const action = args[0].?;
    const eq = args[1].?;
    const hit = psx.getBits(&action.hitParams[0], "affinity");
    const aff: c_int = if (hit != 0) @as(c_int, hit) - 1 else args[2];
    const target: usize = @intCast(aff);
    if (eq.affinities[target] >= 100) return 0;
    if (target == 0) return 1;
    if (args[4] != 0) return 3;
    return 2;
}
