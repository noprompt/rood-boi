//! zig_diff spec: func_8007DF20 -> func_8007DF20.func_8007DF20 (146C.c).
//! Inputs: the global D_800F1A44 (a u32) set to edges: 0, 1, 0x7FFFFFFF, the
//! sign bit alone, all ones, and the 16-bit boundary values; otherwise random.
//! The function has no branches and no calls: it returns the u32's bits as a
//! c_int, so the classes split on zero, a positive value, and the sign bit.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DF20));

pub const classes = [_][:0]const u8{ "zero", "positive", "sign-bit" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F1A44().* = ctx.pick(u32, &.{
        0,
        1,
        0x7FFF_FFFF,
        0x8000_0000,
        0xFFFF_FFFF,
        0x0001_0000,
        0x0000_8000,
    });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.D_800F1A44().*;
    if (x == 0) return 0;
    if (x & 0x8000_0000 != 0) return 2;
    return 1;
}
