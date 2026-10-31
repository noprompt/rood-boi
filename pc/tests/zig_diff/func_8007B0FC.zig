//! zig_diff spec: func_8007B0FC -> func_8007B0FC.func_8007B0FC (146C.c).
//! The C body is empty: no branches, no calls, no argument, no global read.
//! The inputs are the harness's random state (arena, globals, scratchpad and
//! PS1 low RAM), which an empty port must leave untouched. The mutations add
//! stores to that state, and the inputs must catch each one.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B0FC));

pub const classes = [_][:0]const u8{"empty"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
