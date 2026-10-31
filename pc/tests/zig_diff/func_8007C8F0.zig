//! zig_diff spec: func_8007C8F0 -> func_8007C8F0.func_8007C8F0 (146C.c).
//! The C body is `return 0;`: it takes no arguments, reads no globals and calls
//! nothing, so there are no branches or value edges to cover. The inputs are
//! the random arena and scratchpad the harness fills on every iteration, and
//! the port must return 0 whatever they hold. There is one input class, since
//! every run is the same call.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C8F0));

pub const classes = [_][:0]const u8{"always"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
