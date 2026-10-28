//! zig_diff spec: func_8007B764 -> func_8007B764.func_8007B764 (146C.c).
//! Inputs: the battle state flag (0, 2, 3 and 255 as edges, so `>= 3` sees
//! equal values often) and the loot list head (null or a fresh arena node).
//! The three calls are recording stubs; the loot callee writes the node's
//! actorId, as a real loot pickup would, and tolerates a null argument so a
//! mutant that calls it with null gives a trace mismatch rather than a crash.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B764));

pub const classes = [_][:0]const u8{ "low-state", "loot", "no-loot" };

/// The state flag the stub returns, chosen by prepare (the same in both runs).
var state_flag: u8 = 0;

pub const stubs = struct {
    pub fn vs_battle_getStateFlag(ctx: *zd.Ctx, id: anytype) u8 {
        _ = ctx;
        _ = id;
        return state_flag;
    }

    pub fn func_800CB158(ctx: *zd.Ctx, node: anytype) void {
        const n: *v.vs_battle_lootListNode = @ptrCast(@alignCast(node orelse return));
        n.actorId = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    state_flag = ctx.edge(u8, &.{ 0, 2, 3, 3, 4, 255 });
    if (ctx.chance(2)) {
        const node = ctx.alloc(v.vs_battle_lootListNode);
        v.g._lootListHead().* = node;
    } else {
        v.g._lootListHead().* = null;
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (state_flag < 3) return 0;
    if (v.g._lootListHead().* != null) return 1;
    return 2;
}
