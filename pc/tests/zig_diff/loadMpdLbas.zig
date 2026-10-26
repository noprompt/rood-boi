//! zig_diff spec: _loadMpdLbas -> load_mpd_lbas.loadMpdLbas (146C.c).
//! Inputs: arg0 is an arena block (or null), and size covers 0, small positive
//! values, -1, INT_MIN and INT_MAX, plus random ints (sign bit both ways). The
//! size==0 branch is taken about 7% of runs. vs_main_allocHeap returns a fresh
//! arena block, sometimes null (the C stores psx_addr(NULL) and never tests it).
//! vs_main_memcpy and vs_main_nop9 record their arguments; the C reads nothing
//! back from memcpy, so its recording stub writes nothing.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").loadMpdLbas));

pub const classes = [_][:0]const u8{ "size-zero", "size-positive", "size-negative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const block = ctx.allocBytes(16, 16);
    const arg0: ?*anyopaque = if (ctx.chance(8)) null else @ptrCast(block);
    const size = ctx.pick(c_int, &.{ 0, 1, 16, 4096, -1, std.math.minInt(c_int), std.math.maxInt(c_int) });
    return .{ arg0, size };
}

pub fn classify(args: Args) usize {
    if (args[1] == 0) return 0;
    if (args[1] < 0) return 2;
    return 1;
}

pub const stubs = struct {
    /// The C does not test the result: a null block is stored as guest address 0.
    pub fn vs_main_allocHeap(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        _ = size;
        if (ctx.value(u8) < 32) return null;
        return @ptrCast(ctx.allocBytes(16, 16));
    }
};
