//! zig_diff spec: func_8008EB30 -> func_8008EB30.func_8008EB30 (146C.c).
//! Inputs: a five-word block in the arena (arg0) with random words, biased
//! toward the mask edges (top byte clear or set, bit 23 set, the sign bit).
//! The C copies the block into D_800F1D78 through vs_main_memcpy (the stub
//! does the copy), then writes the words it reads, masked to 24 bits and
//! tagged 0x30 in the top byte, into D_80068C1C. The loops take fixed counts,
//! so every branch is taken on every run; the words decide the values.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008EB30));

pub const classes = [_][:0]const u8{ "top-byte-clear", "top-byte-set" };

pub const stubs = struct {
    /// The real memcpy writes the destination bytes (D_800F1D78 is read by
    /// the port's state compare, and a dropped call leaves it stale).
    pub fn vs_main_memcpy(ctx: *zd.Ctx, dest: anytype, src: anytype, sz: anytype) void {
        _ = ctx;
        const n: usize = @intCast(sz);
        const d = bytes(dest);
        const s = bytes(src);
        @memcpy(d[0..n], s[0..n]);
    }

    fn bytes(p: anytype) [*]u8 {
        const q = if (@typeInfo(@TypeOf(p)) == .optional) p.? else p;
        return @ptrCast(@alignCast(q));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const words = ctx.alloc([5]c_int);
    for (words) |*w| {
        w.* = ctx.pick(c_int, &.{ 0, -1, 0x00FFFFFF, 0x01000000, 0x00800000, -2147483648, 2147483647 });
    }
    // Sometimes force the top byte clear or set, so both classes occur.
    if (ctx.chance(2)) {
        words[0] &= 0x00FFFFFF;
    } else {
        words[0] |= @as(c_int, @bitCast(@as(u32, 0xFF000000)));
    }
    const p: [*c]c_int = words;
    return .{p};
}

pub fn classify(args: Args) usize {
    const w = args[0];
    return if (@as(u32, @bitCast(w[0])) >> 24 == 0) 0 else 1;
}
