//! zig_diff spec: func_800CF48C -> func_800CF48C.func_800CF48C (5BF94.c).
//! The C body is a single return of the global D_800F531C, a u32, as an int.
//! Inputs: the global set to zero, to small values, to values with the sign
//! bit set (the int reinterpretation), and to the all-ones and wrap edges.
//! Random fill covers the rest of the 32-bit range.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF48C));

pub const classes = [_][:0]const u8{ "zero", "sign-clear", "sign-set" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F531C().* = ctx.pick(u32, &.{
        0,          1,          0x7FFF_FFFF, 0x8000_0000,
        0xFFFF_FFFF, 0xFFFF,    0x8000,      0x7FFF,
        0x1_0000,   0xFFFF_0000,
    });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.D_800F531C().*;
    if (x == 0) return 0;
    if (x & 0x8000_0000 != 0) return 2;
    return 1;
}
