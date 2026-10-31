//! zig_diff spec: func_800CB66C -> func_800CB66C.func_800CB66C (5BF94.c).
//! The C takes no arguments, has no branches and calls nothing: it returns
//! the address of the global D_800F4E98. The inputs are the empty argument
//! tuple; the global keeps the random fill from the harness, and the compared
//! return value is the address itself, so a wrong constant or a different
//! field offset in the port is a mismatch on every iteration.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB66C));

pub const classes = [_][:0]const u8{"always"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
