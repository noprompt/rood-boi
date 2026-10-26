//! zig_diff spec: func_8008A6FC -> func_8008A6FC.func_8008A6FC (146C.c).
//! Inputs: a loot list of 0 to 3 nodes in the arena, linked and terminated by
//! null, with the head global set to the first node (or null when empty).
//! The free stub overwrites the freed node's first word (its next link), as a
//! heap header write would, so a port that reads `next` after the free differs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008A6FC));

pub const classes = [_][:0]const u8{ "empty", "one-node", "two-nodes", "three-nodes" };

var count: usize = 0;

pub fn prepare(ctx: *zd.Ctx) Args {
    const nodes = [_]*v.vs_battle_lootListNode{
        ctx.alloc(v.vs_battle_lootListNode),
        ctx.alloc(v.vs_battle_lootListNode),
        ctx.alloc(v.vs_battle_lootListNode),
    };
    count = ctx.range(usize, 0, 3);
    var next: ?*v.vs_battle_lootListNode = null;
    var i = count;
    while (i > 0) {
        i -= 1;
        psx.put(&nodes[i].next, next);
        next = nodes[i];
    }
    v.g._lootListHead().* = next;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return count;
}

pub const stubs = struct {
    pub fn vs_main_freeHeapR(ctx: *zd.Ctx, p: anytype) void {
        // The heap overwrites the block's first word (the next link).
        const bytes: [*]u8 = @ptrCast(p.?);
        const w: *align(1) u32 = @ptrCast(bytes);
        w.* = ctx.value(u32);
    }
};
