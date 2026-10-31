//! zig_diff spec: func_800D1930 -> func_800D1930.func_800D1930 (5BF94.c).
//! The function takes no arguments and calls nothing. It clears four globals
//! (D_800F5518, D_800F55E8, D_800F54D0, D_800F55A0) and sets the unk0 byte of
//! each of the four D_800F54B8 entries to 0xFF. The inputs are the random
//! state the harness already gives every run: the C's stores overwrite
//! whatever is there, so every touched byte is compared against the port.
//! The only branch is the loop test `i < 4`, which both runs take on every
//! iteration (the exit test sees i == 4 on both sides).
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D1930));

pub const classes = [_][:0]const u8{"any"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
