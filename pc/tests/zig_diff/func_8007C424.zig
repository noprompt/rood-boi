//! zig_diff spec: func_8007C424 -> func_8007C424.func_8007C424 (146C.c).
//! The C body is one call to func_80089D04 and nothing else: no arguments,
//! no branches, no value edges. The inputs are the random arena, globals and
//! scratchpad the harness fills each iteration. The callee is a recording
//! stub (void, no return value). Nothing the C reads comes back from the
//! call, so the stub writes nothing. The mutations check that the call is
//! made exactly once, in place.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C424));

pub const classes = [_][:0]const u8{"the-call"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
