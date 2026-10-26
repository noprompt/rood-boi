//! zig_diff spec: func_8007DF48 -> func_8007DF48.func_8007DF48 (146C.c).
//! Inputs: none. The function takes no arguments and its only inputs are the
//! globals D_800F19A8 (32 bytes) and D_800F18F8, which start as random bytes
//! in the harness. Both loops and the final store run on every call, so each
//! iteration checks the whole 32-byte table and the flag byte. The loop
//! conditions compare the counter with constants and no data value reaches a
//! branch, so there is one input class.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DF48));

pub const classes = [_][:0]const u8{"run"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
