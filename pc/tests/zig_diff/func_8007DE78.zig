//! zig_diff spec: func_8007DE78 -> func_8007DE78.func_8007DE78 (146C.c).
//! The C is a single load: it returns the i16 global D_800F1A2C. The inputs set
//! that global to the sign, zero and wrap edges (0, -1, 1, 32767, -32768) half
//! the time and leave it as random bytes otherwise, so a port that returns a
//! different width, sign or byte of the global fails. There are no arguments,
//! no calls and no branches in the C.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DE78));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const g = v.g.D_800F1A2C();
    g.* = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.D_800F1A2C().*;
    if (x < 0) return 0;
    if (x == 0) return 1;
    return 2;
}
