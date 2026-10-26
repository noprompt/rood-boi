//! zig_diff spec: func_80089CE4 -> func_80089CE4.func_80089CE4 (146C.c).
//! The unit takes no arguments and reads no globals; its only effect is the
//! call SetDispMask(1). The inputs are the random state the harness supplies
//! on each iteration: the arena, the globals and the scratchpad. The single
//! class covers every run, since the function has no branches or value edges.
//! The SetDispMask call is recorded with its argument and the state hash, so
//! a port that passes another mask, skips the call or calls it twice differs.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80089CE4));

pub const classes = [_][:0]const u8{"always"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
