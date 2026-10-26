//! zig_diff spec: func_800856F8 -> func_800856F8.func_800856F8 (146C.c).
//! The unit is one call: vs_main_bzero(arg0, 0x84C). The inputs are a
//! 0x84C-byte block in the arena, aligned (its base) or starting 1-15 bytes
//! in, so a port that rounds or offsets the pointer is caught. The stub
//! clears the bytes it is given, so the state compare sees the store. The
//! arena block has room past 0x84C for every pointer the stub touches.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800856F8));

pub const classes = [_][:0]const u8{ "aligned", "misaligned" };

pub const stubs = struct {
    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        if (p == null) return;
        const bytes: [*]u8 = @ptrCast(@alignCast(p));
        @memset(bytes[0..@intCast(n)], 0);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const block = ctx.allocBytes(0x84C + 64, 16);
    const off: usize = if (ctx.chance(2)) 0 else ctx.range(usize, 1, 15);
    return .{@ptrCast(block + off)};
}

pub fn classify(args: Args) usize {
    return if (@intFromPtr(args[0].?) & 15 == 0) 0 else 1;
}
