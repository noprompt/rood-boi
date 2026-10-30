//! zig_diff spec: func_800CF1A8 -> func_800CF1A8.func_800CF1A8 (5BF94.c).
//! Inputs: a chain of 0-4 D_800F53B8_t nodes in the arena, linked by psx
//! pointers and ended by a null next, with the head global set by prepare.
//! Each node's unkD1C.unk30 is null or points at an arena object (two
//! spares shared across nodes, or a fresh object), so the free-and-clear
//! branch runs for some nodes and not others. The stub of func_800CE8F4
//! rewrites the next node's unk30 (read back by the loop) and sometimes nulls
//! the current node's next (read back only by a port that re-reads it after
//! the call). The classes are: empty chain, chain with no owned object, chain
//! with one owned object, and chain with several owned objects.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF1A8));

pub const classes = [_][:0]const u8{ "empty", "clear", "owned-single", "owned-multi" };

var spare_a: ?*v.D_800F53B8_t4 = null;
var spare_b: ?*v.D_800F53B8_t4 = null;

pub const stubs = struct {
    pub fn func_800CE8F4(ctx: *zd.Ctx, node: anytype) void {
        const n: *v.D_800F53B8_t = @ptrCast(@alignCast(node));
        // The next node's owned object: read back by the loop's next iteration.
        if (psx.get(n.next)) |nx| {
            const target: ?*v.D_800F53B8_t4 = switch (ctx.value(u2)) {
                0 => null,
                1 => spare_a,
                2 => spare_b,
                else => spare_a,
            };
            psx.put(&nx.unkD1C.unk30, target);
        }
        // The current node's next: only a port that re-reads it after the call sees this.
        if (ctx.value(u2) == 0) psx.put(&n.next, null);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    spare_a = ctx.alloc(v.D_800F53B8_t4);
    spare_b = ctx.alloc(v.D_800F53B8_t4);

    var nodes: [4]*v.D_800F53B8_t = undefined;
    const count = ctx.range(usize, 0, 4);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        const node = ctx.alloc(v.D_800F53B8_t);
        nodes[i] = node;
        const obj: ?*v.D_800F53B8_t4 = switch (ctx.range(u8, 0, 3)) {
            0 => null,
            1 => spare_a,
            2 => spare_b,
            else => ctx.alloc(v.D_800F53B8_t4),
        };
        psx.put(&node.unkD1C.unk30, obj);
        psx.put(&node.next, null);
        if (i > 0) psx.put(&nodes[i - 1].next, node);
    }

    v.g.D_800F53B8().* = if (count == 0) null else nodes[0];
    return .{};
}

pub fn classify(_: Args) usize {
    var n: ?*v.D_800F53B8_t = v.g.D_800F53B8().*;
    var count: usize = 0;
    var owned: usize = 0;
    while (n) |node| {
        count += 1;
        if (psx.get(node.unkD1C.unk30) != null) owned += 1;
        n = psx.get(node.next);
    }
    if (count == 0) return 0;
    if (owned == 0) return 1;
    return if (owned == 1) 2 else 3;
}
