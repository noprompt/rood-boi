//! zig_diff spec: func_800D268C -> func_800D268C.func_800D268C (5BF94.c).
//! The C body is a single store: D_800F5600 = 0. The inputs are the empty
//! argument list and a random D_800F5600 (prepare sets it to a random i32 so
//! the store always changes it, and sometimes it is already 0). There are no
//! branches, callees or arena objects, so the only observable effects are the
//! final value of the global and the rest of the state, which must match.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D268C));

pub const classes = [_][:0]const u8{"store"};

pub fn prepare(ctx: *zd.Ctx) Args {
    // Sometimes the global already holds 0, sometimes any other value.
    v.g.D_800F5600().* = ctx.pick(i32, &.{ 0, 1, -1, std.math.minInt(i32) });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
