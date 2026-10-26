//! zig_diff spec: _loadMpdEnemySection -> load_mpd_enemy_section.loadMpdEnemySection (146C.c).
//! Inputs: a data pointer into the arena (the copy is a recording stub, so it
//! is never read) and a dataLen over zero, the small values around
//! sizeof(_mpdEnemy) = 40 (the division), the 2^31 and 2^32-1 extremes (the
//! signed/unsigned slip), and random values. The allocator stub hands out an
//! arena block for small sizes and returns null sometimes, so the stored
//! pointer is both a real address and 0.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").loadMpdEnemySection));

pub const classes = [_][:0]const u8{ "zero-length", "small-length", "sign-bit-length" };

pub const stubs = struct {
    /// The heap: an arena block for a small request, null now and then (the
    /// C stores psx_addr of whatever comes back).
    pub fn vs_main_allocHeap(ctx: *zd.Ctx, n: anytype) ?*anyopaque {
        if (n > 4096 or ctx.value(u8) < 32) return null;
        return @ptrCast(ctx.allocBytes(n, 16));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const len = ctx.pick(c_uint, &.{ 0, 1, 39, 40, 41, 80, 0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF });
    const data: ?*anyopaque = @ptrCast(ctx.allocBytes(64, 16));
    return .{ data, len };
}

pub fn classify(args: Args) usize {
    const len = args[1];
    if (len == 0) return 0;
    if ((len & 0x8000_0000) != 0) return 2;
    return 1;
}
