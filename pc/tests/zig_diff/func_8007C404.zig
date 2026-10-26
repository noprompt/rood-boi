//! zig_diff spec: func_8007C404 -> func_8007C404.func_8007C404 (146C.c).
//! The C body is one call to func_80089CE4 and nothing else, so there are no
//! branches or value edges to cover. The inputs are the empty argument list
//! over random state. The callee is a recording stub that takes no context
//! and writes nothing: the harness compares the state hash at the call, the
//! call's presence and count, and the state after the body. Whatever the
//! real callee leaves behind is a state effect a port must reproduce by
//! making the same call. There is one input class, since the body has no
//! inputs to split on.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C404));

pub const classes = [_][:0]const u8{"always"};

pub const stubs = struct {
    pub fn func_80089CE4(ctx: *zd.Ctx) void {
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
