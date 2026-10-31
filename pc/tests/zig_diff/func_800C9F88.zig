//! zig_diff spec: func_800C9F88 -> func_800C9F88.func_800C9F88 (5BF94.c).
//! The C body is a single store, D_800EBC78 = 1. It takes no arguments,
//! tests nothing and calls nothing, so the only input is the global's prior
//! value. Prepare sets it to an edge (0, 1, 0x80 or 0xFF) or a random byte
//! every iteration, so a store that keeps some of the old bits, ORs instead
//! of assigning, or writes a different constant changes the state the
//! harness compares.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800C9F88));

pub const classes = [_][:0]const u8{ "old-0", "old-1", "old-80", "old-ff", "old-other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800EBC78().* = ctx.pick(u8, &.{ 0, 1, 0x80, 0xFF });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return switch (v.g.D_800EBC78().*) {
        0 => 0,
        1 => 1,
        0x80 => 2,
        0xFF => 3,
        else => 4,
    };
}
