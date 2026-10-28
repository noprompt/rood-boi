//! zig_diff spec: func_8007CF80 -> func_8007CF80.func_8007CF80 (146C.c).
//! Inputs: the 16-entry vs_battle_actors table, each entry null (1 in 4) or an
//! arena actor whose allegiance (u16) is an edge value (0, 1, 0xFF, 0x100,
//! 0x101, 0xFFFF, 0x8000), and an argument taken from one entry's allegiance
//! (exact, +0x100, +0x10000, negated) or from edge values (0, -1, 1, 0xFFFF,
//! INT_MAX, INT_MIN). Covered: null entries, matching and non-matching
//! entries, arguments whose high bits differ from the allegiance (a u16 or
//! u8 truncation shows), negative arguments, and the loop bound at 16.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CF80));

pub const classes = [_][:0]const u8{ "no-match", "one-match", "several-matches", "high-bits", "negative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        if (ctx.chance(4)) {
            table[i] = null;
            continue;
        }
        const actor = ctx.alloc(v.vs_battle_actor);
        actor.allegiance = ctx.pick(u16, &.{ 0, 1, 0xFF, 0x100, 0x101, 0xFFFF, 0x8000 });
        table[i] = actor;
    }
    const k = ctx.range(usize, 0, 15);
    const base: c_int = if (table[k]) |a| @as(c_int, a.allegiance) else 0;
    const arg: c_int = switch (ctx.range(u8, 0, 5)) {
        0, 1 => base,
        2 => base +% 0x100,
        3 => base +% 0x10000,
        4 => -base,
        else => ctx.pick(c_int, &.{ 0, -1, 1, 0xFFFF, 0x7FFFFFFF, -0x80000000 }),
    };
    return .{arg};
}

pub fn classify(args: Args) usize {
    const arg = args[0];
    if (arg < 0) return 4;
    if (arg > 0xFFFF) return 3;
    const table = v.g.vs_battle_actors();
    var n: usize = 0;
    for (0..16) |i| {
        if (table[i]) |a| {
            if (@as(c_int, a.allegiance) == arg) n += 1;
        }
    }
    if (n == 0) return 0;
    if (n == 1) return 1;
    return 2;
}
