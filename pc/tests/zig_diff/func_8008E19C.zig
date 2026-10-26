//! zig_diff spec: func_8008E19C -> func_8008E19C.func_8008E19C (146C.c).
//! Inputs: arg0 and arg1 at, just below and past the edges where `+ 0x80`
//! overflows (and their i16 truncation), arg1 negative and positive, arg2 at
//! the i16 extremes, and arg3 at byte edges (0, 0xFF, 0x100, all ones, the sign
//! bit). D_800F19C8 and D_800E8594 come from the random fill, so the call trace
//! carries a random value. The callee is a recording stub: the C reads nothing
//! back after it, so it needs no state-changing model. The loop's `i < 3` test
//! always meets its equal sides at i == 3.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E19C));

pub const classes = [_][:0]const u8{ "arg0-overflows-plus-0x80", "arg1-negative", "plain" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const a0 = ctx.pick(c_int, &.{ 0, -1, 0x7FFF_FF7F, 0x7FFF_FF80, std.math.maxInt(c_int), std.math.minInt(c_int) });
    const a1 = ctx.pick(c_int, &.{ 0, -128, -129, 0x7FFF_FF80, 0x7FFF, 0x8000 });
    const a2 = ctx.pick(c_short, &.{ 0, -1, 32767, -32768 });
    const a3 = ctx.pick(c_uint, &.{ 0, 0xFF, 0x100, 0xFFFF_FFFF, 0x8000_0000 });
    return .{ a0, a1, a2, a3 };
}

pub fn classify(args: Args) usize {
    if (args[0] > 0x7FFF_FF7F) return 0;
    if (args[1] < 0) return 1;
    return 2;
}
