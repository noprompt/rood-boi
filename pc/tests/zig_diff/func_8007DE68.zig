//! zig_diff spec: func_8007DE68 -> func_8007DE68.func_8007DE68 (146C.c).
//! The C body is one load: it returns the i32 global D_800F1B98. The inputs
//! set that global to the edges (0, -1, 1, the i32 extremes) half the time
//! and to any i32 otherwise, so the negative, zero and positive results all
//! occur and narrowing or sign mistakes show up in the returned value.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DE68));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F1B98().* = ctx.pick(i32, &.{ 0, -1, 1, std.math.maxInt(i32), std.math.minInt(i32), 0x7FFF, -0x8000, 0x8000 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.D_800F1B98().*;
    if (x < 0) return 0;
    if (x == 0) return 1;
    return 2;
}
