//! zig_diff spec: func_800CE83C -> func_800CE83C.func_800CE83C (5BF94.c).
//! Inputs: a list of 0-4 nodes in the arena, sorted by unk9 (ascending, with
//! duplicates from saturating adds), linked by guest pointers and ending in a
//! null next; the head is sometimes null. The argument's unk10 is an i32 that
//! is often equal to a node's unk9 (the ordered comparisons see equal sides),
//! sometimes a signed edge (-1, minInt, maxInt), otherwise a random value.
//! The new node comes from the allocator stub; func_800CE714 is a recording
//! stub that writes the new node's unk8/unk9, sometimes rewrites arg0->unk10
//! (which the C reads back), and sometimes clears the list head (the C reads
//! the head after the call).
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CE83C));

pub const classes = [_][:0]const u8{ "empty-list", "front", "equal-front", "middle", "append", "equal-later" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.alloc(v.D_800F53B8_t2);
    const count = ctx.range(usize, 0, 4);
    var nodes: [4]*v.D_800F53B8_t = undefined;
    var level: u8 = ctx.range(u8, 0, 200);
    for (0..count) |i| {
        const node = ctx.alloc(v.D_800F53B8_t);
        node.unk9 = level;
        level +|= ctx.range(u8, 0, 40);
        nodes[i] = node;
    }
    for (0..count) |i| {
        const next: ?*v.D_800F53B8_t = if (i + 1 < count) nodes[i + 1] else null;
        psx.put(&nodes[i].next, next);
    }
    var head: ?*v.D_800F53B8_t = if (count == 0) null else nodes[0];
    if (ctx.chance(12)) head = null;
    v.g.D_800F53B8().* = head;

    const pivot: i32 = blk: {
        if (count > 0 and ctx.chance(2)) break :blk nodes[ctx.range(usize, 0, count - 1)].unk9;
        break :blk ctx.pick(i32, &.{ -1, 0, 1, 127, 128, 255, 256, std.math.minInt(i32), std.math.maxInt(i32) });
    };
    arg.unk10 = pivot;
    return .{arg};
}

pub fn classify(args: Args) usize {
    const arg = args[0].?;
    const head = v.g.D_800F53B8().* orelse return 0;
    if (arg.unk10 < head.unk9) return 1;
    if (arg.unk10 == head.unk9) return 2;
    var cur = head;
    while (true) {
        const next = psx.get(cur.next) orelse return 4;
        if (arg.unk10 == next.unk9) return 5;
        if (arg.unk10 < next.unk9) return 3;
        cur = next;
    }
}

pub const stubs = struct {
    /// Always a valid arena block: the C writes through the result.
    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        _ = size;
        return @ptrCast(ctx.allocBytes(@sizeOf(v.D_800F53B8_t), 16));
    }

    /// Writes the new node's fields, sometimes the argument's unk10 (read back
    /// by the C's comparisons) and sometimes the list head (read back after the call).
    pub fn func_800CE714(ctx: *zd.Ctx, arg0: anytype, node: anytype) void {
        const a: *v.D_800F53B8_t2 = @ptrCast(@alignCast(arg0));
        const n: *v.D_800F53B8_t = @ptrCast(@alignCast(node));
        n.unk8 = ctx.value(u8);
        n.unk9 = ctx.value(u8);
        if (ctx.value(u8) < 128) a.unk10 = ctx.value(i32);
        if (ctx.value(u8) < 8) v.g.D_800F53B8().* = null;
    }
};
