//! zig_diff spec: func_800CEF64 -> func_800CEF64.func_800CEF64 (5BF94.c).
//! The C returns whether the global D_800F54A8 (a u8) is nonzero. The inputs
//! set that byte to each shape the test can see: zero, 1 (only bit 0), 0x80
//! (only the sign bit), 0x7F (every bit but the sign bit), and other values.
//! The function takes no arguments and makes no calls.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CEF64));

pub const classes = [_][:0]const u8{ "zero", "one", "sign-bit", "other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const flag = v.g.D_800F54A8();
    // Edge values half the time (zero, 1, the sign bit alone, bits without
    // the sign bit); otherwise any byte, which is rarely zero.
    flag.* = ctx.pick(u8, &.{ 0, 1, 0x80, 0xFF, 0x7F, 0x81 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const f = v.g.D_800F54A8().*;
    if (f == 0) return 0;
    if (f == 1) return 1;
    if (f & 0x80 != 0) return 2;
    return 3;
}
