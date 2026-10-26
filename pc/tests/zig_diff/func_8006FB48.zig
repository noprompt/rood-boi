//! zig_diff spec: func_8006FB48 -> func_8006FB48.func_8006FB48 (146C.c).
//! Inputs: the state flag the stub returns (0, 1, 2, 3, 4 and 255, so the
//! `> 2` test sees its two sides equal and both outcomes), and the loot list
//! head (null in about a third of the runs, otherwise a fresh arena node).
//! The stubs write the globals the real callees may change (_cameraMode,
//! D_800F196C, the loot list head) with ctx.value, so a port that reads them
//! back around the calls is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006FB48));

pub const classes = [_][:0]const u8{ "flag-at-most-2", "loot-list", "no-loot-list" };

/// The flag vs_battle_getStateFlag returns in this iteration (set by prepare,
/// read by the stub; the same in the C run and the Zig run).
var flag: u8 = 0;

pub fn prepare(ctx: *zd.Ctx) Args {
    flag = ctx.edge(u8, &.{ 0, 1, 2, 3, 4, 255 });
    const head = v.g._lootListHead();
    head.* = if (ctx.chance(3)) null else ctx.alloc(v.vs_battle_lootListNode);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (flag <= 2) return 0;
    return if (v.g._lootListHead().* != null) 1 else 2;
}

pub const stubs = struct {
    pub fn vs_battle_getStateFlag(ctx: *zd.Ctx, id: anytype) u8 {
        _ = ctx;
        _ = id;
        return flag;
    }
    pub fn func_800CB158(ctx: *zd.Ctx, node: anytype) void {
        _ = node;
        // The callee may consume the list (the C does not read the head back).
        if (ctx.value(u1) == 1) v.g._lootListHead().* = null;
    }
    pub fn func_8006F89C(ctx: *zd.Ctx) void {
        // The callee may set D_800F196C; the C reads it back only through the harness.
        v.g.D_800F196C().* = ctx.value(u32);
    }
    pub fn func_8006F5FC(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g._cameraMode().* = ctx.value(u32);
    }
};
