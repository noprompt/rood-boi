//! zig_diff spec: func_8008B4B0 -> func_8008B4B0.func_8008B4B0 (146C.c).
//! The function takes no arguments and has no branches or calls: it stores 0 to
//! the i16 global D_800F1BB6. The inputs leave that global as random bytes most
//! of the time, and sometimes already 0, so both a changed and an unchanged
//! store are seen. Mutations change the stored value or drop the store.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B4B0));

pub const classes = [_][:0]const u8{ "already-zero", "nonzero" };

pub fn prepare(ctx: *zd.Ctx) Args {
    // Sometimes the global already holds 0, so the store changes nothing.
    if (ctx.chance(4)) v.g.D_800F1BB6().* = 0;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F1BB6().* == 0) 0 else 1;
}
