//! zig_diff spec: func_8007BA98 -> func_8007BA98.func_8007BA98 (146C.c).
//! Inputs: the four ids and counts from edges that matter (low 16 bits zero
//! or not, sign bit set or not, counts that wrap through the u8 fields), and
//! the loot list head either null or a node in the arena. The allocator
//! returns null about one time in eight; bzero zeroes the block it is given,
//! so the node's bytes match what the C expects; func_800CB158 may rewrite
//! the node's actorId, which the C never reads back but the state compare sees.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BA98));

pub const classes = [_][:0]const u8{
    "no-loot-head-empty",
    "no-loot-head-set",
    "first-loot-head-empty",
    "first-loot-head-set",
    "second-loot-head-empty",
    "second-loot-head-set",
    "both-loot-head-empty",
    "both-loot-head-set",
};

pub const stubs = struct {
    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        if (ctx.value(u8) < 32) return null; // the C's NULL test
        return @ptrCast(ctx.allocBytes(@intCast(size), 16));
    }

    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const raw: ?*anyopaque = p;
        const bytes: [*]u8 = @ptrCast(raw.?);
        const len: usize = @intCast(n);
        @memset(bytes[0..len], 0);
    }

    pub fn func_800CB158(ctx: *zd.Ctx, list: anytype) void {
        const raw: ?*anyopaque = list;
        if (raw) |r| {
            const node: *v.vs_battle_lootListNode = @ptrCast(@alignCast(r));
            if (ctx.value(u1) == 1) node.actorId = ctx.value(i32);
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const head = v.g._lootListHead();
    if (ctx.chance(2)) {
        head.* = null;
    } else {
        head.* = ctx.alloc(v.vs_battle_lootListNode);
    }

    const id_edges = [_]c_int{ 0, 1, -1, 0x10000, -65536, 0x10001, -65535, 0x7FFF0000 };
    const count_edges = [_]c_int{ 0, 1, 255, 256, -1, 0x100, 0x7FFFFFFF, -2147483648 };
    const id0 = ctx.pick(c_int, &id_edges);
    const count0 = ctx.pick(c_int, &count_edges);
    const id1 = ctx.pick(c_int, &id_edges);
    const count1 = ctx.pick(c_int, &count_edges);
    return .{ id0, count0, id1, count1 };
}

pub fn classify(args: Args) usize {
    const first: usize = if ((args[0] & 0xFFFF) != 0) 1 else 0;
    const second: usize = if ((args[2] & 0xFFFF) != 0) 2 else 0;
    const head: usize = if (v.g._lootListHead().* != null) 1 else 0;
    return (first | second) * 2 + head;
}
