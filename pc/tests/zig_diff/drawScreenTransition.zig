//! zig_diff spec: _drawScreenTransition -> draw_screen_transition.drawScreenTransition (146C.c).
//! Inputs: the transition globals (effect 0-5 and -1, step 0-7, alpha around 0,
//! 255 and the signed range, speed around the 255-speed and speed bounds, wipe
//! angle around zero) and a frame buffer index of 0 or 1. Alpha equals 255-speed
//! or speed often enough for the signed `>=` and `<=` tests to see equal sides.
//! RotMatrix_gte records the Z rotation it was given, and RotTrans returns
//! values that depend on it, so the wipe-hold angle reaches the output. RotTrans
//! also writes any i32, so the C's narrowing of projected values to i16 is exercised.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").drawScreenTransition));

pub const classes = [_][:0]const u8{
    "idle",
    "fade-black",
    "fade-white-255",
    "fade-white-partial",
    "wipe-hold",
    "wipe-run",
    "other-effect",
};

/// The Z rotation the last RotMatrix_gte call was given. Set and read in the
/// same run, in the same order, so both runs see the same value.
var last_z: i16 = 0;

pub const stubs = struct {
    pub fn RotMatrix_gte(ctx: *zd.Ctx, r: anytype, m: anytype) [*c]v.MATRIX {
        _ = ctx;
        _ = m;
        const sv: *const v.SVECTOR = @ptrCast(@alignCast(r));
        last_z = sv.vz;
        return null;
    }

    pub fn RotTrans(ctx: *zd.Ctx, v0: anytype, v1: anytype, flag: anytype) void {
        _ = v0;
        const out: *v.VECTOR = @ptrCast(@alignCast(v1));
        const z: i32 = last_z;
        out.vx = ctx.value(i32) +% z;
        out.vy = ctx.value(i32);
        out.vz = ctx.value(i32);
        const f: *c_int = @ptrCast(@alignCast(flag));
        f.* = ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const ot: ?*anyopaque = @ptrCast(ctx.allocBytes(64, 16));

    v.g.vs_main_frameBuf().* = ctx.edge(i32, &.{ 0, 1 });
    v.g.vs_battle_screenTransitionEffect().* = ctx.pick(i32, &.{ 0, 1, 2, 3, 4, 5, -1 });
    v.g.vs_battle_screenTransitionStep().* = ctx.pick(u32, &.{ 0, 1, 2, 3, 4, 5, 6, 7 });

    const speed: i32 = if (ctx.chance(3))
        ctx.edge(i32, &.{ 0, 1, -1, 255, 256, -255 })
    else
        ctx.range(i32, -1000, 1000);
    v.g.vs_battle_screenTransitionSpeed().* = speed;

    var alpha: i32 = if (ctx.chance(6))
        0
    else if (ctx.chance(3))
        ctx.edge(i32, &.{ 1, -1, 254, 255, 256, -255 })
    else
        ctx.range(i32, -3000000, 3000000);
    // Equal sides of the signed `>=` (fade in) and `<=` (fade out) tests.
    if (ctx.chance(4)) alpha = 255 - speed;
    if (ctx.chance(6)) alpha = speed;
    v.g.vs_battle_screenTransitionAlpha().* = alpha;

    v.g.vs_battle_screenTransitionWipeAngle().* = ctx.range(i32, -100000, 100000);

    return .{ot};
}

pub fn classify(args: Args) usize {
    _ = args;
    const alpha = v.g.vs_battle_screenTransitionAlpha().*;
    const effect = v.g.vs_battle_screenTransitionEffect().*;
    const step = v.g.vs_battle_screenTransitionStep().*;
    if (alpha == 0) return 0;
    return switch (effect) {
        0, 4, 5 => 1,
        1 => if (alpha == 255) 2 else 3,
        2 => if (step == 4 or step == 7) 4 else 5,
        else => 6,
    };
}
