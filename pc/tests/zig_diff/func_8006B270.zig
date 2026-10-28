//! zig_diff spec: func_8006B270 -> func_8006B270.func_8006B270 (146C.c).
//! Inputs: vs_battle_characterState points at an arena actor whose stats
//! pointer targets an arena vs_battle_actor2 with random bytes. Its statuses
//! word comes from edge values (every masked bit alone, masked zero with and
//! without the sign bit, the sign bit with and without the mask) or any i32.
//! The two callees are recording stubs that sometimes rewrite statuses, so
//! a port that caches the masked value across the first call differs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006B270));

pub const classes = [_][:0]const u8{ "no-status", "status-no-sign", "status-sign" };

/// The stats block prepare built, so the stubs can change its statuses.
var cur_stats: ?*v.vs_battle_actor2 = null;

pub const stubs = struct {
    pub fn func_80093FEC(ctx: *zd.Ctx, a: anytype, b: anytype, m: anytype, d: anytype) void {
        _ = .{ a, b, m, d };
        // Sometimes the callee clears or rewrites the statuses the C reads again.
        if (ctx.value(u2) == 0) if (cur_stats) |s| {
            s.statuses = ctx.value(i32);
        };
    }

    pub fn func_80086754(ctx: *zd.Ctx, m: anytype, p: anytype) void {
        _ = m;
        const a: *v.vs_battle_actor2 = @ptrCast(@alignCast(p));
        // The callee gets the stats block and may change its statuses.
        if (ctx.value(u2) == 0) a.statuses = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    psx.put(&actor.stats, stats);
    v.g.vs_battle_characterState().* = actor;
    cur_stats = stats;
    stats.statuses = ctx.pick(i32, &.{
        0,
        1,
        0x00100000,
        -2147483648, // sign bit only: masked zero, negative
        1 << 21,
        1 << 22,
        1 << 23,
        1 << 24,
        0x01000000,
        0x01E00000,
        -2130706432, // 0x81000000: sign bit and bit 24
        -1,
    });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const actor = v.g.vs_battle_characterState().*.?;
    const stats = psx.get(actor.stats).?;
    const s = stats.statuses;
    if ((s & 0x01E00000) == 0) return 0;
    return if (s < 0) 2 else 1;
}
