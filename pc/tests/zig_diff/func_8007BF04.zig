//! zig_diff spec: func_8007BF04 -> func_8007BF04.func_8007BF04 (146C.c).
//! The C body is empty: no arguments, no calls, no branches and no globals
//! read. The harness's randomised state (the arena, the scratchpad and every
//! global either side reaches) is the whole input, and the check is that the
//! port leaves all of it untouched. With no branches there is one input class,
//! which always occurs.
const std = @import("std");
const zd = @import("zdiff");
const port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_8007BF04));

pub const classes = [_][:0]const u8{"empty"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
