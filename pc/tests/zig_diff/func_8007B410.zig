//! zig_diff spec: func_8007B410 -> func_8007B410.func_8007B410 (146C.c).
//! Inputs: none. The C has no branches and no comparisons, and it reads no
//! global or argument: it makes five fixed calls and then stores 1 to
//! D_800F1968. The one input variation is the random initial state of the
//! arena, the scratchpad and the globals, which the harness randomises every
//! iteration. The callees' results and side effects are never read back by
//! the C, so the default recording stubs (void does nothing, int returns
//! ctx.value) are the faithful model. The state hash taken at each call is
//! what catches a store moved across a call.
const std = @import("std");
const zd = @import("zdiff");
const port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_8007B410));

pub const classes = [_][:0]const u8{"always"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
