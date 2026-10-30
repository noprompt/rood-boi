//! zig_diff spec: func_800CB660 -> func_800CB660.func_800CB660 (5BF94.c).
//! The C is one store: D_800EB9CC = arg0, truncated to the global's u8. There
//! are no branches, calls or pointers. The inputs cover the edge values of an
//! int (0, 1, -1, 255, 256, 0x100, INT_MAX, INT_MIN) and random ints, so the
//! low byte is zero in some runs and nonzero in others, and the high bits
//! differ from the low byte. The global starts as random bytes, and prepare
//! also sets it to a random byte, so a port that skips the store is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB660));

pub const classes = [_][:0]const u8{ "low-byte-zero", "other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800EB9CC().* = ctx.int(u8);
    const x: c_int = ctx.pick(c_int, &.{ 0, 1, -1, 255, 256, 0x100, 0x7FFFFFFF, -2147483648 });
    return .{x};
}

pub fn classify(args: Args) usize {
    return if ((@as(u32, @bitCast(args[0])) & 0xFF) == 0) 0 else 1;
}
