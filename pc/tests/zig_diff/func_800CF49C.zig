//! zig_diff spec: func_800CF49C -> func_800CF49C.func_800CF49C (5BF94.c).
//! Inputs: the four entries of D_800F5320, the bitmask table the function scans.
//! Entries below a random index `free_at` are full (-1) or skipped (-2) by the
//! C; the rest are drawn from edge values (-1, -2, -3, 0, 1, INT_MIN, 0x7FFFFFFF
//! with only bit 31 free, 0x7FFFFFFE, and others) or any random 32-bit value.
//! The first free entry therefore lands in entry 0, in a later entry, or no
//! entry is free and the outer loop runs out and returns 0. Nothing else is read.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF49C));

pub const classes = [_][:0]const u8{ "free-in-entry-0", "free-in-later-entry", "no-free-entry" };

const edges = [_]i32{ -1, -2, -3, 0, 1, 0x7FFF_FFFF, 0x7FFF_FFFE, -2147483648, -4, 0x5555_5555, 0x4000_0000 };
const full = [_]i32{ -1, -2 };

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = v.g.D_800F5320();
    const free_at = ctx.range(u8, 0, 4);
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        d[i] = if (i < free_at) ctx.edge(i32, &full) else ctx.pick(i32, &edges);
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F5320();
    for (0..4) |i| {
        const x: u32 = @bitCast(d[i]);
        if (x == 0xFFFF_FFFE) continue;
        if (((~x) & 0xFFFF_FFFE) != 0) return if (i == 0) 0 else 1;
    }
    return 2;
}
