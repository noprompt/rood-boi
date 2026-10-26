//! zig_diff spec: func_8007B29C -> func_8007B29C.func_8007B29C (146C.c).
//! Inputs: arg2 around the `< 9` test (8, 9, 10, zero, negatives, the int
//! extremes, so the signed compare and the `+ 4` / `+ 1` calls see every
//! side), arg0 and arg1 any int, arg3..arg5 any short with the short edges.
//! Both callees are void recording stubs that take value arguments only:
//! the C reads nothing back from them, and any state they write is in the
//! randomised state the harness compares after each run.
const std = @import("std");
const zd = @import("zdiff");
const port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_8007B29C));

pub const classes = [_][:0]const u8{ "below-nine", "nine", "above-nine" };

pub fn prepare(ctx: *zd.Ctx) Args {
    // Edge values come up often enough that arg2 == 9 happens many times.
    const arg2: c_int = if (ctx.chance(3))
        ctx.edge(c_int, &.{ 8, 9, 10 })
    else
        ctx.pick(c_int, &.{ 9, 8, 10, -1, 0, 0x7FFF_FFFF, -0x8000_0000 });
    const shorts = [_]c_short{ 0, -1, 1, 32767, -32768 };
    return .{
        ctx.int(c_int),
        ctx.int(c_int),
        arg2,
        ctx.pick(c_short, &shorts),
        ctx.pick(c_short, &shorts),
        ctx.pick(c_short, &shorts),
    };
}

pub fn classify(args: Args) usize {
    const arg2 = args[2];
    if (arg2 < 9) return 0;
    if (arg2 == 9) return 1;
    return 2;
}
