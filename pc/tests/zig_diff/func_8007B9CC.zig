//! zig_diff spec: func_8007B9CC -> func_8007B9CC.func_8007B9CC (146C.c).
//! Inputs: no arguments. The globals D_800F1860 and D_800F1864 start as random
//! bytes, and prepare biases the first one toward 0, 1, -1 and the i32 extremes.
//! The C stores 0 and 1 and then calls func_8007B764. The callee may overwrite
//! either global, and the state hash taken at the call catches a port that
//! moves a store across the call.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B9CC));

pub const classes = [_][:0]const u8{ "old-zero", "old-nonzero" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F1860().* = ctx.pick(i32, &.{ 0, 1, -1, std.math.maxInt(i32), std.math.minInt(i32) });
    v.g.D_800F1864().* = ctx.pick(i32, &.{ 0, 1, -1 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F1860().* == 0) 0 else 1;
}

pub const stubs = struct {
    pub fn func_8007B764(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g.D_800F1860().* = ctx.value(i32);
        if (ctx.value(u1) == 1) v.g.D_800F1864().* = ctx.value(i32);
    }
};
