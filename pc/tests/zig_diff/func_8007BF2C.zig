//! zig_diff spec: func_8007BF2C -> func_8007BF2C.func_8007BF2C (146C.c).
//! Inputs: none. The function takes no arguments and the C body is a single
//! call, func_8008AB80(0), whose int result it discards, so there are no
//! branches, comparisons or globals to steer. The callee is a recording stub:
//! its argument and the state hashed at the call are compared, and its return
//! value is drawn from ctx.value, which the C never reads back. A port that
//! passes a different argument, drops the call, or repeats it is caught.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BF2C));

/// The C has no branches or value edges: every run is the same input class.
pub const classes = [_][:0]const u8{"always"};

pub const stubs = struct {
    pub fn func_8008AB80(ctx: *zd.Ctx, arg: anytype) c_int {
        _ = arg;
        return ctx.value(c_int);
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
