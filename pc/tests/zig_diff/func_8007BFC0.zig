//! zig_diff spec: func_8007BFC0 -> func_8007BFC0.func_8007BFC0 (146C.c).
//! The unit takes no arguments and reads no globals: it calls
//! func_8007BF6C(i) for i = 0..15 in order. The inputs are the state the
//! harness randomises around the call. The callee is a recording stub that
//! records its argument and changes nothing, since the C never reads back
//! anything the callee could write. Each of the 16 calls is traced, so a
//! wrong bound, a wrong start, a wrong step or a dropped call mismatches.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
const c = @import("c_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BFC0));

pub const classes = [_][:0]const u8{"run"};

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}

pub const stubs = struct {
    pub fn func_8007BF6C(ctx: *zd.Ctx, i: anytype) void {
        _ = ctx;
        _ = i;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}
