//! zig_diff spec: func_8008B6B4 -> func_8008B6B4.func_8008B6B4 (146C.c).
//! Inputs: no arguments. The unit has no branches, so the inputs are the
//! globals it writes: D_800F1D6A and D_800F1D6C (random bytes, so the stores
//! must overwrite them) and the 64-byte D_800F1D28 table, which the callee
//! zeroes. Half the runs set D_800F1D6C to 0 first, so the class shows whether
//! the store changes the value. The vs_main_bzero stub models that callee: it
//! zeroes the bytes it is given, so a port that passes the wrong size or skips
//! the call leaves different bytes behind.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B6B4));

pub const classes = [_][:0]const u8{ "d6c-already-zero", "d6c-nonzero" };

pub const stubs = struct {
    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const q: ?*anyopaque = p;
        const bytes: [*]u8 = @ptrCast(q.?);
        @memset(bytes[0..@intCast(n)], 0);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(2)) v.g.D_800F1D6C().* = 0;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F1D6C().* == 0) 0 else 1;
}
