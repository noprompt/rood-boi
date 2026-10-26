//! zig_diff spec: func_8007E1C0 -> func_8007E1C0.func_8007E1C0 (146C.c).
//! Inputs: the global byte D_800F18F8 (any value, so the high bit is set half
//! the time) and an int argument chosen against it: equal to the byte (the
//! match path, which clears the byte and returns 1), equal to the byte read as
//! a signed char (only differs from the byte when its high bit is set), the
//! byte plus 256 (high bits set, must miss), and edge values (0, -1, INT_MIN,
//! INT_MAX, 256, random). The miss path calls vs_main_nop9(0x67, 0) and
//! returns 0. vs_main_nop9 is a recording stub: the C never reads anything
//! back after the call, so the stub needs no behaviour.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007E1C0));

pub const classes = [_][:0]const u8{ "match", "signed-match", "miss" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const flag = v.g.D_800F18F8();
    const b = ctx.int(u8);
    flag.* = b;
    const arg: c_int = switch (ctx.range(u8, 0, 9)) {
        0...4 => @as(c_int, b),
        5 => @as(c_int, b) +% 256,
        6, 7 => @as(c_int, @as(i8, @bitCast(b))),
        8 => ctx.pick(c_int, &.{ 0, -1, 0x7FFF_FFFF, -2147483648, 256 }),
        else => ctx.int(c_int),
    };
    return .{arg};
}

pub fn classify(args: Args) usize {
    const b = v.g.D_800F18F8().*;
    const arg = args[0];
    if (arg == @as(c_int, b)) return 0;
    if (b >= 128 and arg == @as(c_int, @as(i8, @bitCast(b)))) return 1;
    return 2;
}
