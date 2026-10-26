//! zig_diff spec: _loadZndEnemies -> load_znd_enemies.loadZndEnemies (146C.c).
//! Inputs: a data block whose first word is the enemy count, with the count
//! at zero, negative (sign bit set), small, wide, and past the 2^28 point
//! where count * 8 wraps in int. The allocator stubs hand back one fixed arena
//! block or null; the memcpy calls are recording stubs, so the C never reads
//! past data[0]. Every branch and each value edge (zero, sign, overflow) is
//! reached through `classify`.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").loadZndEnemies));

pub const classes = [_][:0]const u8{ "zero", "negative", "small", "wide", "overflow" };

pub const stubs = struct {
    /// Returns null sometimes, otherwise a fixed arena block the memcpy stubs
    /// record by address only. A fixed address keeps both runs' traces equal.
    pub fn vs_main_allocHeap(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        _ = size;
        if (ctx.value(u8) < 32) return null;
        const p: *anyopaque = @ptrCast(&zd.zdiff_arena[64 * 1024]);
        return p;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const count: c_int = switch (ctx.range(u8, 0, 3)) {
        0 => ctx.edge(c_int, &.{ 0, 0, 1, 2, 63, 64 }),
        1 => ctx.range(c_int, -64, -1),
        2 => ctx.range(c_int, 65, 0x0FFF_FFFF),
        else => ctx.edge(c_int, &.{
            0x1000_0000,  0x2000_0000,  0x3FFF_FFFF, 0x4000_0000, 0x7FFF_FFFF,
            -0x1000_0000, -0x1000_0001, -0x7FFF_FFFF, -0x8000_0000,
        }),
    };
    const words: [*]c_int = @ptrCast(@alignCast(ctx.allocBytes(16, 16)));
    words[0] = count;
    return .{ words, ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const n = args[0][0];
    if (n == 0) return 0;
    if (n < 0) return 1;
    if (n <= 64) return 2;
    if (n <= 0x0FFF_FFFF) return 3;
    return 4;
}
