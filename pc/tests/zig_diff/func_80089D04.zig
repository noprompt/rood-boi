//! zig_diff spec: func_80089D04 -> func_80089D04.func_80089D04 (146C.c).
//! Inputs: none. The unit is one call, SetDispMask(0). The C has no branches
//! and no values it tests, so the spec's one class always applies. The
//! recording stub for SetDispMask is void and writes nothing the C reads back.
//! The harness compares the call's argument, the call trace and the state.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80089D04));

pub const classes = [_][:0]const u8{"call"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
