//! zig_diff spec: func_8007B4C4 -> func_8007B4C4.func_8007B4C4 (146C.c).
//! Inputs: the D_800F1864 flag (prepared as zero, negative, or positive, with
//! the extremes), and random _cameraMode. The callee func_8007B470 rewrites
//! the flag, sometimes to zero, and _cameraMode sometimes, so the C's test
//! and the call trace both depend on what the callee left behind.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B4C4));

pub const classes = [_][:0]const u8{ "flag-zero", "flag-negative", "flag-positive" };

pub const stubs = struct {
    pub fn func_8007B470(ctx: *zd.Ctx) void {
        const x = ctx.value(i32);
        v.g.D_800F1864().* = if (ctx.value(u1) == 1) 0 else x;
        if (ctx.value(u1) == 1) v.g._cameraMode().* = ctx.value(u32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F1864().* = ctx.pick(i32, &.{ 0, 1, -1, 0x7FFFFFFF, -0x80000000 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const f = v.g.D_800F1864().*;
    if (f == 0) return 0;
    if (f < 0) return 1;
    return 2;
}
