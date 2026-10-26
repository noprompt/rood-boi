//! zig_diff spec: func_8007DDAC -> func_8007DDAC.func_8007DDAC (146C.c).
//! Inputs: an arbitrary c_int argument, biased toward the edges around the
//! i16 range the store truncates to (0, +-1, 32767, -32768, 32768, -32769,
//! 65535, 65536, the int limits). The C reads no object and makes no call;
//! the only observable effect is the 16-bit store to D_800F1A2C, which the
//! harness compares byte for byte.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DDAC));

pub const classes = [_][:0]const u8{ "fits-i16", "truncated" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const x = ctx.pick(c_int, &.{
        0,      1,      -1,         32767,      -32768,
        32768,  -32769, 65535,      65536,      0x7FFF_FFFF,
        -0x7FFF_FFFF - 1, 0x0000_8001,
    });
    return .{x};
}

pub fn classify(args: Args) usize {
    const x = args[0];
    return if (x >= -32768 and x <= 32767) 0 else 1;
}
