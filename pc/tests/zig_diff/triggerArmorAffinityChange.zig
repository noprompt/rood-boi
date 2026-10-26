//! zig_diff spec: _triggerArmorAffinityChange -> trigger_armor_affinity_change.triggerArmorAffinityChange (146C.c).
//! Inputs: an action whose hitParams[0].affinity is 0 (the argument is used, 0..6) or 1..7 (the
//! argument is overridden, so its random value is never used), an equipment block with random
//! i8 affinities biased to -100, 99, 100, -128 and 127, and an actorId that is 0 half the time.
//! The stubs return 20..59 from vs_main_getRand, so both sides of each threshold test are
//! reached and often equal. func_80096768 sometimes rewrites an affinity, as a callee that
//! reads and writes the equipment could.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").triggerArmorAffinityChange));

pub const classes = [_][:0]const u8{ "capped", "self-affinity-zero", "other-affinity" };

/// The equipment the current run was prepared with; the stubs write into it.
var current_equip: ?*v.vs_battle_uiEquipment = null;

pub const stubs = struct {
    pub fn vs_main_getRand(ctx: *zd.Ctx, n: anytype) c_int {
        _ = n;
        return @as(c_int, 20 + ctx.value(u8) % 40);
    }

    pub fn func_80096768(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) void {
        _ = a;
        _ = b;
        _ = c;
        if (ctx.value(u2) == 0) {
            const eq = current_equip.?;
            const idx = ctx.value(u3);
            eq.affinities[idx] = ctx.value(i8);
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const equip = ctx.alloc(v.vs_battle_uiEquipment);
    current_equip = equip;
    for (0..8) |i| {
        equip.affinities[i] = ctx.pick(i8, &.{ -100, -101, 99, 100, -128, 127, 0, 98 });
    }
    const hit: u3 = if (ctx.chance(2)) 0 else ctx.range(u3, 1, 7);
    psx.setBits(&action.hitParams[0], "affinity", hit);
    const affinity: c_int = if (hit == 0) ctx.range(c_int, 0, 6) else ctx.int(c_int);
    const actorId: c_int = if (ctx.chance(2)) 0 else ctx.pick(c_int, &.{ 1, -1, 2 });
    return .{ action, equip, affinity, ctx.int(c_int), actorId };
}

fn targetOf(e: c_int) usize {
    return switch (e) {
        0 => 0,
        1 => 3,
        2 => 4,
        3 => 1,
        4 => 2,
        5 => 6,
        6 => 5,
        else => 0,
    };
}

pub fn classify(args: Args) usize {
    const action = args[0].?;
    const equip = args[1].?;
    var eff: c_int = args[2];
    const hit = psx.getBits(&action.hitParams[0], "affinity");
    if (hit != 0) eff = @as(c_int, hit) - 1;
    const target = targetOf(eff);
    if (equip.affinities[target] >= 100) return 0;
    if (eff == 0) return 1;
    return 2;
}
