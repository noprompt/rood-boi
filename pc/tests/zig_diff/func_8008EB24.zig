//! zig_diff spec: func_8008EB24 -> func_8008EB24.func_8008EB24 (146C.c).
//! Inputs: none. The function has no arguments, branches, callees or
//! comparisons. It returns the address of the global D_800F1D78, which the
//! harness fills with random bytes and which both runs reach at the same
//! address. The only thing to check is the returned pointer, so every
//! iteration exercises the same path, and the mutations below change the
//! returned address (an off-by-one element, a wrong element, a null return).
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008EB24));

pub const classes = [_][:0]const u8{"always"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
