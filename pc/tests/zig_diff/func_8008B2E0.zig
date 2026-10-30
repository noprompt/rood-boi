//! zig_diff spec: func_8008B2E0 -> func_8008B2E0.func_8008B2E0 (146C.c).
//! Inputs: the global D_800F1BA8 is set to a pointer into the middle of an arena
//! block, so the destination lands before or after the block for large negative
//! indices. arg1 is a small row (-8..8), arg2 a column (-300..300 with the edges),
//! arg3 a halfword count (-600..600 with the edges, so arg3 * 2 is negative
//! sometimes). arg0 is null or an arena block. The memcpy stub copies only when
//! both ranges lie in the arena and the count is at most 512, so the C never
//! touches memory the harness does not own.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B2E0));

pub const classes = [_][:0]const u8{ "null-src", "negative-count", "other" };

pub const stubs = struct {
    pub fn vs_main_memcpy(ctx: *zd.Ctx, dest: anytype, src: anytype, sz: anytype) void {
        _ = ctx;
        const d: usize = @intFromPtr(dest orelse return);
        const s: usize = @intFromPtr(src orelse return);
        const n: usize = sz;
        const base = @intFromPtr(&zd.zdiff_arena[0]);
        const end = base + zd.arena_size;
        if (n > 512 or d < base or s < base) return;
        if (d + n > end or s + n > end) return;
        const dst: [*]u8 = @ptrFromInt(d);
        const from: [*]const u8 = @ptrFromInt(s);
        var i: usize = 0;
        while (i < n) : (i += 1) dst[i] = from[i];
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const buf = ctx.allocBytes(8192, 16);
    const base: [*]u16 = @ptrCast(@alignCast(buf + 4096));
    v.g.D_800F1BA8().* = base;

    const arg0: ?*anyopaque = if (ctx.chance(8)) null else @ptrCast(ctx.allocBytes(1024, 16));
    const arg1: c_int = ctx.range(c_int, -8, 8);
    const arg2: c_int = if (ctx.chance(3))
        ctx.edge(c_int, &.{ -1, 0, 1, 255, 256, -255, -256, 299, -300 })
    else
        ctx.range(c_int, -300, 300);
    const arg3: c_int = if (ctx.chance(4))
        ctx.edge(c_int, &.{ 0, 1, -1, 255, 256, -256, 0x3FFF_FFFF, -0x4000_0000 })
    else
        ctx.range(c_int, -600, 600);
    return .{ arg0, arg1, arg2, arg3 };
}

pub fn classify(args: Args) usize {
    if (args[0] == null) return 0;
    if (args[3] < 0) return 1;
    return 2;
}
