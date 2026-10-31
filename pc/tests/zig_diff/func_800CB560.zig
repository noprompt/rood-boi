//! zig_diff spec: func_800CB560 -> func_800CB560.func_800CB560 (5BF94.c).
//! The C is a single store: vs_battle_lowerScreenUiState = 0. It has no
//! branches, calls or arguments. Inputs: the global starts as random bytes
//! (zero about once in 256 runs), and prepare sets it to zero on some
//! iterations so the store is checked both over a nonzero and over an
//! already-zero byte. The classes name which of the two each run starts from.
//! The harness compares the global's byte after the run.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB560));

pub const classes = [_][:0]const u8{ "zero-before", "nonzero-before" };

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(2)) v.g.vs_battle_lowerScreenUiState().* = 0;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.vs_battle_lowerScreenUiState().* == 0) 0 else 1;
}
