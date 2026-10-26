//! zig_diff spec: func_8008B28C -> func_8008B28C.func_8008B28C (146C.c).
//! Inputs: D_800F1BA4 is zero half the time (the ticking branch) and otherwise
//! a nonzero value with or without the high bit (0x100 and 0x80 test the low
//! byte as a signed char). D_800F1CDC is any u16 including 0xFFFF, so the add
//! wraps, and vs_gametime_tickspeed is any i32 including negative values and
//! the extremes, so the stored sum is truncated to 16 bits.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B28C));

pub const classes = [_][:0]const u8{ "ticking", "paused-low", "paused-high" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const flag = v.g.D_800F1BA4();
    flag.* = if (ctx.chance(2)) 0 else ctx.edge(u16, &.{ 1, 0x80, 0x100, 0x7FFF, 0x8000, 0xFFFF });
    v.g.D_800F1CDC().* = ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF });
    v.g.vs_gametime_tickspeed().* = ctx.pick(i32, &.{ 0, 1, -1, 2, -2, 65536, -65536, 0x7FFFFFFF, -0x7FFFFFFF - 1 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const flag = v.g.D_800F1BA4().*;
    if (flag == 0) return 0;
    return if (flag & 0x8000 != 0) 2 else 1;
}
