//! zig_diff spec: func_8008E8F8 -> func_8008E8F8.func_8008E8F8 (146C.c).
//! Inputs: the heap pointer global D_800F1DD4 is either null or an arena
//! block, so the free call runs in one half of the runs and not the other.
//! vs_main_allocHeap returns null about one time in eight, and otherwise a
//! fresh 0x800-byte arena block, so the stored pointer takes both values.
//! vs_main_freeHeap is a recording stub that leaves the heap alone.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E8F8));

pub const classes = [_][:0]const u8{ "old-null", "old-set" };

pub const stubs = struct {
    /// The heap allocator: null when the heap is full (the C stores it as is),
    /// otherwise a block of the size asked for.
    pub fn vs_main_allocHeap(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        _ = size;
        if (ctx.value(u8) < 32) return null;
        return @ptrCast(ctx.allocBytes(0x800, 16));
    }

    /// The heap free: it only records its argument; the heap is left as is.
    pub fn vs_main_freeHeap(ctx: *zd.Ctx, p: anytype) void {
        _ = ctx;
        _ = p;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const heap = v.g.D_800F1DD4();
    heap.* = if (ctx.chance(2)) null else ctx.alloc(v.D_800F1DD4_t);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F1DD4().* == null) 0 else 1;
}
