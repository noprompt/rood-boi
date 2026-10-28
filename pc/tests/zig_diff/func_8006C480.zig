//! zig_diff spec: func_8006C480 -> func_8006C480.func_8006C480 (146C.c).
//! The C is one call, func_800CF7A8(arg0, arg1, 0, 0), with no branches. The
//! inputs are two c_int arguments drawn from edge values (0, +-1, the i32
//! extremes, the 16-bit boundaries) and random bits, so the forwarded values
//! differ between a port that narrows, swaps or re-orders them and one that
//! does not. The callee is a recording stub returning void: the C reads
//! nothing back after the call, so there is nothing for it to change that
//! the unit reads. The harness compares the whole state after the call anyway.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006C480));

pub const classes = [_][:0]const u8{ "arg0-negative", "arg0-nonnegative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const a = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000, 0x8000, -0x8001 });
    const b = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000, 0x8000 });
    return .{ a, b };
}

pub fn classify(args: Args) usize {
    return if (args[0] < 0) 0 else 1;
}
