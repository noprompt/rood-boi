//! zig_diff spec: _computeCameraTransition -> compute_camera_transition.computeCameraTransition (146C.c).
//! Inputs: a target position with per-axis edges (0, +-1, +-4096, the i32 extremes) or
//! random values, and a camera position offset from it by a wrap-free difference, so the
//! horizontal deltas are random i32 values (negative and non-multiples of 4096 included).
//! The vertical offset is at least 8000 in magnitude and the normal's vertical component is
//! at most 15 in magnitude, so transitionFrames is never 0 and the divisions by it cannot
//! trap. The VectorNormal stub reads its input vector and writes it back (truncated to i16),
//! so the horizontal deltas reach the state the C compares. rcos never returns 0.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").computeCameraTransition));

pub const classes = [_][:0]const u8{ "target-below-camera", "target-above-camera", "target-wide-x" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const t = ctx.alloc(v.vs_battle_cameraTransition_t);
    v.g.vs_battle_cameraTransition().* = t;

    const target = ctx.alloc(v.VECTOR);
    const edges = [_]i32{ 0, 1, -1, 4096, -4096, 0x7FFF_FFFF, -0x7FFF_FFFF - 1 };
    target.vx = ctx.pick(i32, &edges);
    target.vy = ctx.pick(i32, &edges);
    target.vz = ctx.pick(i32, &edges);

    const s = v.g.vs_scratch();
    // Each camera position is the target minus a difference: the C's delta is exactly that difference.
    s.camera.position.vx = target.vx -% ctx.int(i32);
    s.camera.position.vz = target.vz -% ctx.int(i32);
    const mag = ctx.range(i32, 8000, 0x7FFF_FFFF);
    const dy: i32 = if (ctx.chance(2)) -mag else mag;
    s.camera.position.vy = target.vy -% dy;

    s.camera.lookAt.vx = ctx.int(i32);
    s.camera.lookAt.vy = ctx.int(i32);
    s.camera.lookAt.vz = ctx.int(i32);
    s.camera.farClip = ctx.int(i32);
    v.g.vs_main_nearClip().* = ctx.int(i32);
    v.g.vs_main_projectionDistance().* = ctx.int(i32);
    return .{target};
}

pub fn classify(args: Args) usize {
    const target = args[0].?;
    const dy = target.vy -% v.g.vs_scratch().camera.position.vy;
    if (dy < 0) return 0;
    if (target.vx > 0x1000_0000 or target.vx < -0x1000_0000) return 2;
    return 1;
}

pub const stubs = struct {
    pub fn VectorNormal(ctx: *zd.Ctx, v0: anytype, v1: anytype) c_int {
        // Read the input first (the C may pass the same vector as both).
        const in: *v.VECTOR = @ptrCast(@alignCast(v0));
        const ix: i32 = @as(i16, @truncate(in.vx));
        const iz: i32 = @as(i16, @truncate(in.vz));
        const out: *v.VECTOR = @ptrCast(@alignCast(v1));
        out.vx = ix;
        out.vz = iz;
        // Odd and at most 15 in magnitude: the frames divisor stays below 2000.
        const k: i32 = 2 * @as(i32, ctx.value(u3)) + 1;
        out.vy = if (ctx.value(u1) == 1) -k else k;
        return ctx.value(c_int);
    }

    pub fn rsin(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        return @as(c_int, ctx.value(i16));
    }

    pub fn rcos(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        // Never 0: the C divides by it.
        return @as(c_int, ctx.value(i16)) | 1;
    }
};
