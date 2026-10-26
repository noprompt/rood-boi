//! zig_diff spec: vs_battle_setFarClip -> set_far_clip.setFarClip (146C.c).
//! Inputs: any farClip, with the edges that matter: 0 (equal to both the
//! sign test and the shifted zero), the sign boundary (-7..-9, INT_MIN and
//! INT_MAX), and 0x4000..0x4008 (shifted to exactly 0x800, and one past it,
//! which takes the clamp). arg1 is 0 three times in four, so the
//! func_80098194 path dominates and arg1 != 0 is still covered. The callee
//! stub sometimes overwrites the camera's farClip, so a port that stores
//! after the call, or reads it back, disagrees with the C.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setFarClip));

pub const classes = [_][:0]const u8{ "arg1-nonzero", "negative", "over-clamp", "in-range" };

pub const stubs = struct {
    pub fn func_80098194(ctx: *zd.Ctx, arg: anytype) void {
        _ = arg;
        if (ctx.value(u1) == 1) v.g.vs_scratch().camera.farClip = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const farClip: c_int = ctx.pick(c_int, &.{
        0,      -1,      -7,                   -8,      -9,
        7,      8,       0x4000,               0x4001,  0x4007,
        0x4008, 0x800,   -0x8000,              std.math.maxInt(c_int), std.math.minInt(c_int),
    });
    const arg1: c_int = if (ctx.chance(4)) ctx.edge(c_int, &.{ 1, -1, 0x7fffffff }) else 0;
    return .{ farClip, arg1 };
}

pub fn classify(args: Args) usize {
    if (args[1] != 0) return 0;
    if (args[0] < 0) return 1;
    if ((args[0] >> 3) > 0x800) return 2;
    return 3;
}
