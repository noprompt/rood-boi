//! zig_diff spec: func_8006FD0C -> func_8006FD0C.func_8006FD0C (146C.c).
//! Inputs: none; the port takes no arguments. The C has no branches and no
//! comparisons, so there is a single input class. The only observable effect
//! is the store of 9 to the u32 global `_cameraMode`. The harness fills that
//! global with random bytes before every iteration, so a run that skips the
//! store, or stores a different value, leaves a different state and is reported.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006FD0C));

pub const classes = [_][:0]const u8{"always"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
