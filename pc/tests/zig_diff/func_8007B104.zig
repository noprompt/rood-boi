//! zig_diff spec: func_8007B104 -> func_8007B104.func_8007B104 (146C.c).
//! The C body is empty, so there are no branches, values or callees to
//! reach. The only class is the empty call. The inputs take no arguments;
//! the random fill of the arena, the scratchpad and low RAM is what both
//! runs leave behind. The mutations add a store to the scratchpad, a store
//! to low RAM and a store to an unmapped host address, so the state
//! comparison and the crash check are both exercised.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B104));

pub const classes = [_][:0]const u8{"empty"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
