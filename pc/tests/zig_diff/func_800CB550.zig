//! zig_diff spec: func_800CB550 -> func_800CB550.func_800CB550 (5BF94.c).
//! The unit takes no arguments, reads no object and calls nothing: it stores
//! 1 into vs_battle_lowerScreenUiState. The global starts as a random byte,
//! so the store is visible whatever it held before, and the mutations that
//! change the stored value or drop the store are caught on the state compare.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB550));

pub const classes = [_][:0]const u8{"store"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
