//! zig_diff spec: func_8007DE38 -> func_8007DE38.func_8007DE38 (146C.c).
//! The C is one store: `D_800F1A20 = arg0;`. The inputs are arg0 drawn from
//! the 32-bit edges (0, +-1, the 16-bit limits, the 32-bit extremes) and
//! random values, split by sign, so the stored global is checked against
//! narrowing, wrapping and sign slips. The global starts as random bytes
//! and is compared in full. The C has no branches and no calls, so there
//! are no stubs.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DE38));

pub const classes = [_][:0]const u8{ "negative", "non-negative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg: c_int = ctx.pick(c_int, &.{
        0,
        1,
        -1,
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
    return if (args[0] < 0) 0 else 1;
}
