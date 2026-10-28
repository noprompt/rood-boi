//! zig_diff spec: func_80074294 -> func_80074294.func_80074294 (146C.c).
//! Inputs: the global D_800F1868 is set by prepare to the edge values 0, -1,
//! 3, 4, 7 and the i32 extremes half the time, and is otherwise random
//! bytes. The C has no branch and no call, so its classes split on the sign
//! bit of the global the function reads. The low two bits are random, so
//! masks 1, 2, 3 and 7 all differ on some input.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80074294));

pub const classes = [_][:0]const u8{ "sign-clear", "sign-set" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F1868().* = ctx.pick(i32, &.{ 0, -1, 3, 4, 7, std.math.minInt(i32), std.math.maxInt(i32) });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F1868().* < 0) 1 else 0;
}
