//! zig_diff spec: func_8007B9FC -> func_8007B9FC.func_8007B9FC (146C.c).
//! Inputs: _cameraMode drawn from the switch's cases (3, 4, 5, 6), the
//! values just beside them (2, 7), 0, all-ones and a high-bit value, so every
//! case and the default run. The four callees are recording stubs; each may
//! overwrite _cameraMode (the C reads it once, before its calls, so a port
//! that re-reads it after a call differs). They return void.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B9FC));

pub const classes = [_][:0]const u8{ "mode3", "mode4", "mode5", "mode6", "other" };

pub const stubs = struct {
    pub fn func_8007B834(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g._cameraMode().* = ctx.value(u32);
    }
    pub fn func_8007B884(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g._cameraMode().* = ctx.value(u32);
    }
    pub fn func_8007B908(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g._cameraMode().* = ctx.value(u32);
    }
    pub fn func_8007B938(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g._cameraMode().* = ctx.value(u32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g._cameraMode().* = ctx.pick(u32, &.{ 0, 2, 3, 4, 5, 6, 7, 0xFFFF_FFFF, 0x8000_0003 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return switch (v.g._cameraMode().*) {
        3 => 0,
        4 => 1,
        5 => 2,
        6 => 3,
        else => 4,
    };
}
