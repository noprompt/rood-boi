//! zig_diff spec: func_80069DBC -> func_80069DBC.func_80069DBC (146C.c).
//! The unit has no branches and no comparisons: it clears D_80060064 and
//! zero-fills D_80061078 (4 entries of 328 bytes) through vs_main_bzero. The
//! inputs are the random state the harness already gives: the global is set
//! to any value and the table's bytes are random before each run. The stub
//! for vs_main_bzero zeroes the bytes it is given, as the real routine does,
//! and the harness compares the call's arguments and the state at the call,
//! so a wrong size, a wrong pointer, a dropped call or a store moved across
//! the call all show.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80069DBC));

pub const classes = [_][:0]const u8{"clear"};

pub const stubs = struct {
    /// The real routine zeroes n bytes at p.
    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const raw: *anyopaque = @as(?*anyopaque, p) orelse @panic("zdiff: null bzero target");
        const bytes: [*]u8 = @ptrCast(@alignCast(raw));
        const len: usize = @intCast(n);
        @memset(bytes[0..len], 0);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
