//! zig_diff spec: func_800CF70C -> func_800CF70C.func_800CF70C (5BF94.c).
//! Inputs: an owner object whose unkD1C.unk34 heads a singly linked list of
//! arena nodes that always contains arg1: either arg1 is the head, or 1-3
//! nodes precede it. arg1->next is an arena node or null, and arg1->unk8 is
//! null, an arena block, arg1 itself (the free stub scribbles over it, so the
//! C reads the scribbled next), or a pointer with the sign bit set (only
//! tested, never dereferenced). vs_main_freeHeapR is a recording stub that
//! overwrites the first word of an arena block it is given with null or an
//! arena address, so the scribbled next stays a valid guest address.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF70C));

pub const classes = [_][:0]const u8{ "unk8-null", "unk8-sign-bit", "head-is-arg1", "walk-one", "walk-loop" };

pub const stubs = struct {
    pub fn vs_main_freeHeapR(ctx: *zd.Ctx, p: anytype) void {
        const q: ?*anyopaque = p;
        const base: usize = @intFromPtr(&zd.zdiff_arena[0]);
        // Always draw, so both runs make the same draws in the same order.
        const w: usize = if (ctx.value(u1) == 1) 0 else base + @as(usize, ctx.value(u16) % 4096) * 8;
        const addr: usize = @intFromPtr(q orelse return);
        if (addr >= base and addr - base <= zd.arena_size - 8) {
            const dst: *align(1) usize = @ptrFromInt(addr);
            dst.* = w;
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const owner = ctx.alloc(v.D_800F53B8_t);
    const node = ctx.alloc(v.func_800D4910_t);
    const after = ctx.alloc(v.func_800D4910_t);
    after.next = null;
    if (ctx.chance(4)) {
        node.next = null;
    } else {
        node.next = after;
    }

    var head: *v.func_800D4910_t = node;
    if (!ctx.chance(3)) {
        const len = ctx.range(u8, 1, 3);
        var i: u8 = 0;
        while (i < len) : (i += 1) {
            const pre = ctx.alloc(v.func_800D4910_t);
            pre.next = head;
            head = pre;
        }
    }
    psx.put(&owner.unkD1C.unk34, head);

    if (ctx.chance(4)) {
        node.unk8 = null;
    } else if (ctx.chance(3)) {
        const bits: usize = (@as(usize, 1) << 63) | @as(usize, ctx.int(u63));
        node.unk8 = @as(*anyopaque, @ptrFromInt(bits));
    } else if (ctx.chance(4)) {
        node.unk8 = node;
    } else {
        node.unk8 = ctx.alloc([2]u64);
    }

    return .{ owner, node };
}

pub fn classify(args: Args) usize {
    const owner = args[0].?;
    const node = args[1].?;
    const u8p: ?*anyopaque = node.unk8;
    if (u8p == null) return 0;
    if (@intFromPtr(u8p.?) >> 63 != 0) return 1;
    const head = psx.get(owner.unkD1C.unk34).?;
    if (head == node) return 2;
    const hn: ?*const anyopaque = head.next;
    if (hn == @as(?*const anyopaque, node)) return 3;
    return 4;
}
