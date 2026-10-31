//! zig_diff spec: func_800719DC -> func_800719DC.func_800719DC (146C.c).
//! The C body is one call, func_80070F28(0), and ignores its argument, so the
//! only inputs are arg0 itself (any c_int, since the C never reads it) and the
//! state around the call, which the harness randomises. There are no branches
//! and no value edges to reach. func_80070F28 is a recording stub that changes
//! nothing: the C reads no state back after the call, and it returns void.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
const c = @import("c_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800719DC));

pub const classes = [_][:0]const u8{"any-arg"};

pub const stubs = struct {
    pub fn func_80070F28(ctx: *zd.Ctx, x: anytype) void {
        _ = ctx;
        _ = x;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.int(c_int)};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
