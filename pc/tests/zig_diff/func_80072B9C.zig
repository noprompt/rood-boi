//! zig_diff spec: func_80072B9C -> func_80072B9C.func_80072B9C (146C.c).
//! The C body is one store: `_cameraMode = 0`. It takes no arguments and has
//! no branches, so there is nothing to build but the global. The harness fills
//! `_cameraMode` (and the rest of the state) with random bytes before each run,
//! so a port that leaves any of its four bytes alone, or writes another value,
//! mismatches on the state comparison. No calls are made, so there are no stubs.
//! There is a single input class, since every run takes the same path.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80072B9C));

pub const classes = [_][:0]const u8{"always"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
