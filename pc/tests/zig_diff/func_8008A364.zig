//! zig_diff spec: func_8008A364 -> func_8008A364.func_8008A364 (146C.c).
//! The unit takes no arguments and reads no globals of its own: it calls
//! _removeActorAtIndex(i, 0) for i = 2..15 in order. The inputs are the
//! random arena and state the harness fills; the stub's return value is
//! random and the C ignores it. The spec's job is to catch loop-bound,
//! start, argument, dropped-call and order mistakes through the call trace.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008A364));

/// One input class: the loop always runs its fourteen iterations.
pub const classes = [_][:0]const u8{"all-indices"};

pub const stubs = struct {
    /// The callee's result is ignored by the C. Its state effects are not
    /// modelled here: the harness compares all state bytes, and both runs
    /// get the same stub, so a port that reads state back still agrees.
    pub fn _removeActorAtIndex(ctx: *zd.Ctx, i: anytype, flag: anytype) c_int {
        _ = i;
        _ = flag;
        return ctx.value(c_int);
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
