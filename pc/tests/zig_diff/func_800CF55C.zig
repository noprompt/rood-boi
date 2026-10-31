//! zig_diff spec: func_800CF55C -> func_800CF55C.func_800CF55C (5BF94.c).
//! Inputs: an arg0 node in the arena with an i32 key that is negative, zero,
//! 127/128/255/256, the i32 extremes, or equal to a list key (so `<` sees
//! EQUAL sides). The global D_800F54B0 is a sorted singly linked list of 0-4
//! arena nodes, linked by guest addresses, ending in null, or null itself.
//! The list keys are u8, so the head and loop compares are signed i32 against
//! u8. The allocator stub hands out arena blocks, and the func_800CE714 stub
//! writes the new node's key and sometimes arg0's key, which the C re-reads.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF55C));

pub const classes = [_][:0]const u8{ "empty-list", "insert-at-head", "walk-the-list" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.alloc(v.D_800F53B8_t2);
    arg.unk10 = ctx.pick(i32, &.{ -1, 0, 1, 127, 128, 255, 256, std.math.maxInt(i32), std.math.minInt(i32) });

    const n: usize = ctx.range(u8, 0, 4);
    var keys: [4]u8 = undefined;
    for (0..n) |i| keys[i] = ctx.pick(u8, &.{ 0, 1, 127, 128, 255 });
    var i: usize = 0;
    while (i < n) : (i += 1) {
        var j: usize = i + 1;
        while (j < n) : (j += 1) {
            if (keys[j] < keys[i]) std.mem.swap(u8, &keys[i], &keys[j]);
        }
    }
    // Sometimes the arg's key equals a list key, so the `<` sides are EQUAL.
    if (n > 0 and ctx.chance(3)) arg.unk10 = keys[ctx.range(usize, 0, n - 1)];

    // Build the ascending list from its last node back to its head.
    var head: ?*v.D_800F53B8_t = null;
    var k: usize = n;
    while (k > 0) {
        k -= 1;
        const node = ctx.alloc(v.D_800F53B8_t);
        node.unk9 = keys[k];
        psx.put(&node.next, head);
        head = node;
    }
    v.g.D_800F54B0().* = head;

    return .{arg};
}

pub fn classify(args: Args) usize {
    const head = v.g.D_800F54B0().*;
    if (head == null) return 0;
    return if (args[0].?.unk10 < head.?.unk9) 1 else 2;
}

pub const stubs = struct {
    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        return @ptrCast(ctx.allocBytes(@as(usize, size), 16));
    }

    pub fn func_800CE714(ctx: *zd.Ctx, src: anytype, dst: anytype) void {
        const a: *v.D_800F53B8_t2 = @ptrCast(@alignCast(src));
        const node: *v.D_800F53B8_t = @ptrCast(@alignCast(dst));
        // The new node's key: a random byte, or arg0's key (the C re-reads arg0).
        node.unk9 = if (ctx.value(u2) == 0) ctx.value(u8) else @truncate(@as(u32, @bitCast(a.unk10)));
        node.unk8 = ctx.value(u8);
        // Sometimes the callee changes arg0's key, which the C reads after the call.
        if (ctx.value(u2) == 0) a.unk10 = ctx.value(i32);
    }
};
