//! zig_diff spec: func_8007B1B8 -> func_8007B1B8.func_8007B1B8 (146C.c).
//! The unit has no branches, no loops and no value tests: it passes its five
//! arguments on to four external calls, in order. The inputs cover all of the
//! argument space: arbitrary 32-bit ints for arg0 and arg1, and arbitrary
//! shorts for arg2 to arg4, with edge values (0, +-1, the i16 extremes) drawn
//! half the time, so negative shorts reach the callees' int parameters. The
//! callees are recording stubs: the harness compares each call's arguments and
//! a hash of the state at that call, so a dropped, reordered, retargeted or
//! widened call shows up as a mismatch. Their return type is void, so no
//! stub has to return anything.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B1B8));

pub const classes = [_][:0]const u8{ "short-negative", "short-nonnegative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{
        ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 }),
        ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 }),
        ctx.pick(c_short, &.{ 0, 1, -1, 32767, -32768 }),
        ctx.pick(c_short, &.{ 0, 1, -1, 32767, -32768 }),
        ctx.pick(c_short, &.{ 0, 1, -1, 32767, -32768 }),
    };
}

pub fn classify(args: Args) usize {
    return if (args[2] < 0) 0 else 1;
}
