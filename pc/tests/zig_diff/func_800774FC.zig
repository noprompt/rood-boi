//! zig_diff spec: func_800774FC -> func_800774FC.func_800774FC (146C.c).
//! Inputs: the eight arguments from edge-biased pools (0, +-1, the c_int
//! extremes, random), arg6 null or an arena flags object. func_80077240 returns
//! null (the C's only branch on it) or a fresh arena actor, chosen per run by
//! `fetch_null`. vs_battle_getEmptyObjectDataSlot reports an object queue that
//! drains after a few polls: nonzero values with random sign, and a forced 0 after
//! 12 stub calls so the loop always ends. func_800773BC may rewrite the actor it
//! is handed, which the C returns unchanged.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800774FC));

pub const classes = [_][:0]const u8{ "null-result", "valid-result" };

/// Per-run choice of whether func_80077240 returns null. Set by prepare, read
/// by the stub and by classify; the same in both runs.
var fetch_null: bool = false;

pub const stubs = struct {
    pub fn func_80077240(ctx: *zd.Ctx, a0: anytype, a1: anytype, a2: anytype, a3: anytype, a4: anytype, a5: anytype, a6: anytype, a7: anytype) ?*v.vs_battle_actor {
        _ = .{ a0, a1, a2, a3, a4, a5, a6, a7 };
        if (fetch_null) return null;
        const a = ctx.alloc(v.vs_battle_actor);
        a.id = ctx.value(i32);
        return a;
    }

    pub fn vs_battle_getEmptyObjectDataSlot(ctx: *zd.Ctx) c_int {
        // Drains after a few polls; the forced 0 bounds the loop.
        if (ctx.calls > 12 or ctx.value(u8) < 64) return 0;
        return ctx.value(c_int) | 1;
    }

    pub fn vs_battle_processObjectDataQueue(ctx: *zd.Ctx) c_int {
        return ctx.value(c_int);
    }

    pub fn vs_main_gametimeUpdate(ctx: *zd.Ctx, vsync: anytype) c_int {
        _ = vsync;
        return ctx.value(c_int);
    }

    pub fn func_800773BC(ctx: *zd.Ctx, p: anytype, a1: anytype, a2: anytype, a3: anytype, a4: anytype, a5: anytype) void {
        _ = .{ a1, a2, a3, a4, a5 };
        if (p) |q| {
            const a: *v.vs_battle_actor = @ptrCast(@alignCast(q));
            if (ctx.value(u1) == 1) a.id = ctx.value(i32);
            if (ctx.value(u1) == 1) a.unk8 = ctx.value(u8);
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    fetch_null = ctx.chance(4);
    const flags: ?*v.vs_battle_objectData_flags = if (ctx.chance(3))
        null
    else
        ctx.alloc(v.vs_battle_objectData_flags);
    const edges = &.{ 0, 1, -1, std.math.maxInt(c_int), std.math.minInt(c_int) };
    return .{
        ctx.pick(c_int, edges),
        ctx.pick(c_int, edges),
        ctx.pick(c_int, edges),
        ctx.pick(c_int, edges),
        ctx.pick(c_int, edges),
        ctx.pick(c_int, edges),
        flags,
        ctx.pick(c_int, edges),
    };
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (fetch_null) 0 else 1;
}
