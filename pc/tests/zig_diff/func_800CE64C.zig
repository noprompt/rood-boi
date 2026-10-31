//! zig_diff spec: func_800CE64C -> func_800CE64C.func_800CE64C (5BF94.c).
//! The C body is three calls in a row with no branches, no arguments and no
//! return value, so the inputs are empty: the arguments tuple is empty and
//! every iteration runs the same call sequence over the random state. The
//! callees are void and the C reads nothing they could change, so the default
//! recording stubs suffice. What the harness varies is the state each call
//! starts from (random arena, globals and scratchpad), which the call-trace
//! hashes compare, and the order and presence of the three calls, which the
//! trace records.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CE64C));

pub const classes = [_][:0]const u8{"straight-line"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
