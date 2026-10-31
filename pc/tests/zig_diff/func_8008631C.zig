//! zig_diff spec: func_8008631C -> func_8008631C.func_8008631C (146C.c).
//! Inputs: the 16 battle-actor slots of vs_battle_actors, each a fresh arena
//! actor whose stats pointer is sometimes null (the psx_get guard), and an
//! arena result block for arg4. arg1 is an actor index 0-15; arg0, targetActor
//! and targetLimb take edge values (negative, 255/256 truncation, extremes).
//! The C has no branches of its own: the callees are recording stubs, and the
//! func_80085B10 stub copies its request into the result block, so every field
//! the C writes into sp10 reaches the compared state.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008631C));

pub const classes = [_][:0]const u8{ "stats-null", "stats-set" };

pub const stubs = struct {
    pub fn func_80085B10(ctx: *zd.Ctx, a: anytype, out: anytype, req: anytype, flag: anytype) void {
        _ = a;
        _ = flag;
        const q: *const v.D_800F19CC_t2 = @ptrCast(@alignCast(req));
        if (out) |o| {
            const r: *v.D_800F19CC_t2 = @ptrCast(@alignCast(o));
            r.* = q.*;
            r.unk844.vx = ctx.value(i16);
        }
    }

    pub fn _getActionCost(ctx: *zd.Ctx, a: anytype, stats: anytype, flag: anytype) c_int {
        _ = a;
        _ = stats;
        _ = flag;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        const stats = ctx.alloc(v.vs_battle_actor2);
        psx.put(&actor.stats, if (ctx.chance(8)) null else stats);
        table[i] = actor;
    }
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 255, 256, 0x7FFF_FFFF, -0x8000_0000, 0x0001_0000 });
    const arg1 = ctx.edge(c_int, &.{ 0, 1, 7, 8, 15 });
    const targetActor = ctx.pick(c_int, &.{ 0, 1, -1, 127, 128, 255, 256, 0x1234_5678 });
    const targetLimb = ctx.pick(c_int, &.{ 0, 5, -1, 127, 128, 255, 256, -128 });
    const arg4 = ctx.alloc(v.D_800F19CC_t2);
    return .{ arg0, arg1, targetActor, targetLimb, arg4 };
}

pub fn classify(args: Args) usize {
    const actor = v.g.vs_battle_actors()[@intCast(args[1])];
    return if (psx.get(actor.?.stats) == null) 0 else 1;
}
