//! zig_diff spec: func_8007DF10 -> func_8007DF10.func_8007DF10 (146C.c).
//! The C body is one return of the global D_800F1A20 (an i32). The inputs
//! set that global to signed edges (0, -1, 1, INT_MIN, INT_MAX, the 16-bit
//! boundaries, +-0x10000) half the time and leave it random bytes otherwise,
//! so the sign bit, the high half-word and the low 16 bits all vary. The
//! function has no branches and no calls; the classes only sort runs by the
//! sign and zero of the returned value.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DF10));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F1A20().* = ctx.pick(i32, &.{
        0,
        -1,
        1,
        std.math.minInt(i32),
        std.math.maxInt(i32),
        0xFFFF,
        0x10000,
        -0x10000,
    });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.D_800F1A20().*;
    if (x < 0) return 0;
    if (x == 0) return 1;
    return 2;
}
