//! zig_diff spec: func_8008B4BC -> func_8008B4BC.func_8008B4BC (146C.c).
//! Inputs: arg0 as a c_int across its edges: zero, one, -1, the i16 and u16
//! limits, one past 16 bits, the i32 extremes, and random values. The C stores
//! arg0 into the u16 global D_800F1BA4, so the store truncates modulo 2^16; the
//! harness compares the global's bytes after the call. The function has no
//! branches, so coverage is the four input classes alone.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B4BC));

pub const classes = [_][:0]const u8{ "zero", "negative", "above-16-bits", "u16-range" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg: c_int = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF, -0x8000, 0xFFFF, 0x10000, 0x7FFFFFFF, -0x80000000 });
    return .{arg};
}

pub fn classify(args: Args) usize {
    const a = args[0];
    if (a == 0) return 0;
    if (a < 0) return 1;
    if (a > 0xFFFF) return 2;
    return 3;
}
