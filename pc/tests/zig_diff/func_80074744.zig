//! zig_diff spec: func_80074744 -> func_80074744.func_80074744 (146C.c).
//! Inputs: no arguments. The battle camera's projection distance is set to
//! below, exactly at, and above 272 (signed, so negative values are below),
//! and the camera transition's return value is zero, negative, positive and
//! random (both signs). The callees are recording stubs. The camera callees
//! change nothing the C reads back after the call: the C reads the distance
//! only before its first call.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80074744));

pub const classes = [_][:0]const u8{ "distance-below", "distance-at-272", "distance-above" };

pub const stubs = struct {
    /// Zero, -1 and 1 in some calls, otherwise any value (its sign bit set half the time).
    pub fn _stepCameraTransition(ctx: *zd.Ctx) c_int {
        const r = ctx.value(u8);
        if (r < 64) return 0;
        if (r < 96) return -1;
        if (r < 128) return 1;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const dist = v.g.vs_main_projectionDistance();
    dist.* = ctx.pick(i32, &.{ 271, 272, 273, 272, 0, -1, -272, std.math.maxInt(i32), std.math.minInt(i32) });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const dist = v.g.vs_main_projectionDistance().*;
    if (dist == 272) return 1;
    return if (dist > 272) 2 else 0;
}
