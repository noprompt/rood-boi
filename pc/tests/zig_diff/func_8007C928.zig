//! zig_diff spec: func_8007C928 -> func_8007C928.func_8007C928 (146C.c).
//! Inputs: an index below 16 (its table slot empty or filled), 16 itself, and
//! indices above it including the unsigned-huge values; arg1 any int; arg2
//! null or an arena object. The allocator hands out a vs_battle_actor_dat
//! block from the arena. The callees model what they can change: the actor's
//! unk40 and its stats pointer (read back by the stub), the table slot (which
//! the C re-reads before func_800E6178), and the value func_80077078 returns.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C928));

pub const classes = [_][:0]const u8{ "index-16", "index-above-16", "slot-filled", "slot-empty" };

pub const stubs = struct {
    /// The real allocator returns a block of the requested size, never null here.
    pub fn vs_main_allocHeap(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        return @ptrCast(ctx.allocBytes(@as(usize, size), 16));
    }

    /// May clear the slot the C just filled (the C re-reads it afterwards).
    pub fn func_80076D50(ctx: *zd.Ctx, index: anytype, p1: anytype, p2: anytype, p3: anytype, p4: anytype) void {
        _ = p1;
        _ = p2;
        _ = p3;
        _ = p4;
        if (ctx.value(u2) == 0) v.g.vs_battle_actors()[@as(usize, @intCast(index))] = null;
    }

    /// Reads the actor's unk40 and stats pointer (both written by the C before
    /// the call), may rewrite unk40, and returns a value built from them.
    pub fn func_80077078(ctx: *zd.Ctx, actor: anytype, index: anytype, wep: anytype, arg3: anytype, arg4: anytype) c_int {
        _ = index;
        _ = wep;
        _ = arg3;
        _ = arg4;
        const p = if (@typeInfo(@TypeOf(actor)) == .optional) actor.? else actor;
        const a: *v.vs_battle_actor = @ptrCast(@alignCast(p));
        const lo: i16 = @truncate(a.unk40);
        const hi: u16 = @truncate(psx.rawOf(a.stats));
        if (ctx.value(u2) == 0) a.unk40 = ctx.value(i32);
        return @as(c_int, lo) +% @as(c_int, @as(i16, @bitCast(hi))) +% @as(c_int, ctx.value(i8));
    }

    /// The C ignores the result of this call.
    pub fn func_800E6178(ctx: *zd.Ctx, p: anytype, n: anytype) c_int {
        _ = p;
        _ = n;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    const arg0: c_uint = if (ctx.chance(3))
        ctx.range(c_uint, 0, 15)
    else
        ctx.pick(c_uint, &.{ 15, 16, 17, 0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF });
    if (arg0 < 16) {
        table[arg0] = if (ctx.chance(2)) null else ctx.alloc(v.vs_battle_actor);
    }
    const arg2: ?*v.vs_battle_objectData_flags = if (ctx.chance(2)) null else ctx.alloc(v.vs_battle_objectData_flags);
    return .{ arg0, ctx.int(c_int), arg2 };
}

pub fn classify(args: Args) usize {
    if (args[0] == 16) return 0;
    if (args[0] >= 16) return 1;
    return if (v.g.vs_battle_actors()[args[0]] != null) 2 else 3;
}
