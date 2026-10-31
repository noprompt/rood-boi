//! zig_diff spec: func_8007DF40 -> func_8007DF40.func_8007DF40 (146C.c).
//! The C body is empty: no branch, no call, no global read. The inputs are
//! the empty argument list and a random scratchpad and PS1 RAM (both are
//! compared as state), so the check is that the port also leaves every
//! byte it can reach untouched. The single input class ("empty") is every
//! run. The mutations add stores to the scratchpad and to PS1 address 0,
//! which the random fill must expose.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DF40));

pub const classes = [_][:0]const u8{"empty"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
