//! zig_diff spec: func_800803A4 -> func_800803A4.func_800803A4 (146C.c).
//! Inputs: an action whose type is spell or not, two actors whose weapon and
//! shield gems carry effect 9 or not, PP pairs around the computed bonus
//! (sometimes exactly equal to it, sometimes saturating, sometimes wrapping
//! below zero), arg3 small (so the PP sums stay in range), at the edges, or
//! large but below the int overflow bound, and weaponDrawn with and without
//! the low bit and the sign bit. The unit makes no external calls.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800803A4));

pub const classes = [_][:0]const u8{ "spell", "weapon-undrawn", "shield-nine", "shield-plain" };

fn hasNine(gems: *const [3]v.vs_battle_uiEquipment) bool {
    for (gems) |g| {
        if (g.gemEffects == 9) return true;
    }
    return false;
}

/// ((arg3 / 10) * (100 + plus)) / 100 as the C computes it (no overflow for the inputs below).
fn bonus(arg3: c_int, plus: c_int) c_int {
    return @divTrunc(@divTrunc(arg3, 10) * (100 + plus), 100);
}

/// Sometimes make the maximum equal to the sum the C compares against.
fn equalPp(ctx: *zd.Ctx, cur: u16, max: *u16, t: c_int) void {
    if (!ctx.chance(3)) return;
    const sum: c_int = @as(c_int, cur) + t;
    if (sum >= 0 and sum <= 65535) max.* = @intCast(sum);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const arg1 = ctx.alloc(v.vs_battle_actor2);
    const arg2 = ctx.alloc(v.vs_battle_actor2);
    const actor = ctx.alloc(v.vs_battle_actor);

    psx.setBits(action, "type", if (ctx.chance(4)) 1 else ctx.int(u3));

    const arg3: c_int = switch (ctx.range(u8, 0, 3)) {
        0, 1 => ctx.range(c_int, -2000, 2000),
        2 => ctx.edge(c_int, &.{ 0, 1, 9, 10, 11, -1, -9, -10, -11, 100, -100, 999, -999, 1000 }),
        else => ctx.range(c_int, -190_000_000, 190_000_000),
    };

    for (0..3) |i| arg1.weapon.gems[i].gemEffects = ctx.edge(u8, &.{ 9, 0, 8, 255 });
    for (0..3) |i| arg2.shield.gems[i].gemEffects = ctx.edge(u8, &.{ 9, 0, 8, 255 });

    arg1.weapon.currentPp = ctx.pick(u16, &.{ 0, 1, 100, 65534, 65535 });
    arg1.weapon.maxPp = ctx.pick(u16, &.{ 0, 1, 100, 65535 });
    equalPp(ctx, arg1.weapon.currentPp, &arg1.weapon.maxPp, bonus(arg3, if (hasNine(&arg1.weapon.gems)) 5 else 0));

    arg2.shield.currentPp = ctx.pick(u16, &.{ 0, 1, 100, 65534, 65535 });
    arg2.shield.maxPp = ctx.pick(u16, &.{ 0, 1, 100, 65535 });
    equalPp(ctx, arg2.shield.currentPp, &arg2.shield.maxPp, bonus(arg3, if (hasNine(&arg2.shield.gems)) -5 else 0));

    actor.weaponDrawn = ctx.edge(i32, &.{ 0, 1, 2, 3, -1, -2, std.math.minInt(i32), std.math.maxInt(i32), 0x4000_0000 });

    // The table has 16 entries; the index the C reads must be one of them.
    const idx = ctx.range(u8, 0, 15);
    arg2.unk957 = idx;
    v.g.vs_battle_actors()[idx] = actor;

    return .{ action, arg1, arg2, arg3 };
}

pub fn classify(args: Args) usize {
    if (psx.getBits(args[0].?, "type") == 1) return 0;
    const drawn = v.g.vs_battle_actors()[args[2].?.unk957].?;
    if ((drawn.weaponDrawn & 1) == 0) return 1;
    return if (hasNine(&args[2].?.shield.gems)) 2 else 3;
}
