//! zig_diff spec: func_8007C4D4 -> func_8007C4D4.func_8007C4D4 (146C.c).
//! Inputs: no arguments. The one global, D_800F19A0, starts as random bytes
//! (prepare sometimes zeroes it), so the store of 0 is seen both over zero
//! and over nonzero values. The C has no branches and makes no calls; the
//! whole 4-byte global is compared, so a partial store is caught too.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C4D4));

pub const classes = [_][:0]const u8{ "was-zero", "was-nonzero" };

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(4)) v.g.D_800F19A0().* = 0;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F19A0().* == 0) 0 else 1;
}
