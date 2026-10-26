//! zig_diff spec: func_8007DE2C -> func_8007DE2C.func_8007DE2C (146C.c).
//! The C is one store: D_800F1B9C = arg0. It has no branch and no callee, so
//! the inputs vary only the argument over zero, negative, positive and the
//! 16-bit and 32-bit edges, where a narrowed or saturated store would differ.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DE2C));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    // The global D_800F1B9C starts as random bytes (the harness fills every
    // global the C reaches); the store overwrites it, and both runs must agree.
    const arg = ctx.pick(c_int, &.{
        0,
        -1,
        1,
        32767,
        -32768,
        65535,
        65536,
        -65536,
        std.math.maxInt(c_int),
        std.math.minInt(c_int),
    });
    return .{arg};
}

pub fn classify(args: Args) usize {
    const x = args[0];
    if (x == 0) return 0;
    if (x < 0) return 1;
    return 2;
}
