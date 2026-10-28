//! zig_diff spec: func_8007DF30 -> func_8007DF30.func_8007DF30 (146C.c).
//! The C is a single load: `return D_800F1A40;`, with no calls and no branches.
//! Inputs: the global D_800F1A40 is set by prepare to an edge value half the
//! time (0, 1, -1, INT_MIN, INT_MAX) and is otherwise the random fill. The
//! classes split the return value by sign and zero, so the sign-dependent
//! mistakes (a signed shift for a division, a 16-bit narrowing) are caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DF30));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F1A40().* = ctx.pick(i32, &.{ 0, 1, -1, std.math.minInt(i32), std.math.maxInt(i32) });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.D_800F1A40().*;
    if (x == 0) return 0;
    return if (x < 0) 1 else 2;
}
