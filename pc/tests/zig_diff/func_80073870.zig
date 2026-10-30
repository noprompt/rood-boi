//! zig_diff spec: func_80073870 -> func_80073870.func_80073870 (146C.c).
//! The body has no branch and no comparison: it calls func_800BEC30 (its
//! c_int result is ignored) and then func_80073718 (void). The inputs are
//! the random state the harness fills, so the callees' effects on globals
//! are compared as whole-state bytes. The stubs record the call order and
//! return a `ctx.value` for the c_int result, so a port that drops, repeats
//! or reorders either call is caught by the call traces.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80073870));

pub const classes = [_][:0]const u8{"always"};

pub const stubs = struct {
    pub fn func_800BEC30(ctx: *zd.Ctx) c_int {
        return ctx.value(c_int);
    }

    pub fn func_80073718(ctx: *zd.Ctx) void {
        _ = ctx;
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
