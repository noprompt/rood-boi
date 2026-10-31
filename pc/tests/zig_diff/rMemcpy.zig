//! zig_diff spec: vs_battle_rMemcpy -> r_memcpy.rMemcpy (5BF94.c).
//! Inputs: a copy of 1..4095 bytes between two offsets in one 8 KiB arena
//! buffer, so the regions are disjoint, identical, overlapping forward
//! (dest < src) or overlapping backward (dest > src). Sizes cover 1, 2, 3,
//! 255, 256, 257 and 4095, the values where an 8-bit index or a
//! one-byte-short loop differs. The C has no callees and no globals.
//! Only sizes >= 1 are generated: the C's do-while decrements first, so size
//! <= 0 would walk the index through 2^32 values and fault. For the same
//! reason the `size != 0` test never sees a value with the sign bit set
//! (its operand is size - 1 >= 0); that value flag is waived below.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").rMemcpy));

pub const classes = [_][:0]const u8{ "size-one", "same-pointer", "disjoint", "overlap-forward", "overlap-backward" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const buf = ctx.allocBytes(8192, 16);
    const n: c_int = if (ctx.chance(2))
        ctx.edge(c_int, &.{ 1, 2, 3, 255, 256, 257, 4095 })
    else
        ctx.range(c_int, 1, 4095);
    const d_off = ctx.range(usize, 0, 4096);
    const s_off = if (ctx.chance(8)) d_off else ctx.range(usize, 0, 4096);
    const dest: ?*anyopaque = @ptrCast(buf + d_off);
    const src: ?*const anyopaque = @ptrCast(buf + s_off);
    return .{ dest, src, n };
}

pub fn classify(args: Args) usize {
    const d = @intFromPtr(args[0].?);
    const s = @intFromPtr(args[1].?);
    const n = args[2];
    if (n == 1) return 0;
    if (d == s) return 1;
    const len: usize = @intCast(n);
    if (d + len <= s or s + len <= d) return 2;
    return if (d < s) 3 else 4;
}
