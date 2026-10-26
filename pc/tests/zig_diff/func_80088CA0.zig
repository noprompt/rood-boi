//! zig_diff spec: func_80088CA0 -> func_80088CA0.func_80088CA0 (146C.c).
//! The C body is one store, D_800E8498 = 0, with no arguments, calls or
//! branches. The inputs vary the prior value of the global over three
//! classes (zero, negative, positive, including the sign-bit and extreme
//! values), so a port that skips the store, or stores any other value,
//! leaves a different state and is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80088CA0));

pub const classes = [_][:0]const u8{ "prior-zero", "prior-negative", "prior-positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const g = v.g.D_800E8498();
    if (ctx.chance(4)) {
        g.* = 0;
    } else {
        g.* = ctx.pick(i32, &.{ -1, 1, 0x7FFF_FFFF, -2147483648, 0x8000, -0x8000 });
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.D_800E8498().*;
    if (x == 0) return 0;
    if (x < 0) return 1;
    return 2;
}
