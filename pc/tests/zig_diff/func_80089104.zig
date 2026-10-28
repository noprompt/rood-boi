//! zig_diff spec: func_80089104 -> func_80089104.func_80089104 (146C.c).
//! The C is a single read of the global D_800F18A8 returned as an int, with no
//! branches and no callees. The inputs set that global to edge values (0, 1,
//! -1, the 16-bit and 32-bit extremes, 0x10000) half the time and to any i32
//! otherwise, so the sign, the upper half-word and the wrap-around cases are
//! all exercised. Classes split the runs by zero, negative and positive.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80089104));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F18A8().* = ctx.pick(i32, &.{
        0,
        1,
        -1,
        0x7FFF,
        -0x8000,
        0x10000,
        std.math.maxInt(i32),
        std.math.minInt(i32),
    });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.D_800F18A8().*;
    if (x == 0) return 0;
    return if (x < 0) 1 else 2;
}
