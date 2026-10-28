//! zig_diff spec: _stepCameraTransition -> step_camera_transition.stepCameraTransition (146C.c).
//! Inputs: a transition block in the arena, pointed to by vs_battle_cameraTransition, and random
//! camera state. The Y positions are chosen so the masked currentY, targetY and nextY are often
//! equal (target = current or next up to the low 12 bits, or near them), which exercises both
//! clauses of the arrival test and their boundaries. The direction and speed are edge values
//! (zero, sign flips, the i32 extremes, so the product wraps), and every Y is an edge or random
//! (negative values included). The two clip setters are recording stubs that write the globals
//! they read in the real callee, so a port that reads them back after the call is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").stepCameraTransition));

pub const classes = [_][:0]const u8{ "arrive-first-clause", "arrive-second-clause", "step" };

pub const stubs = struct {
    pub fn vs_battle_setNearClip(ctx: *zd.Ctx, arg0: anytype) void {
        _ = arg0;
        if (ctx.value(u1) == 1) v.g.vs_main_nearClip().* = ctx.value(i32);
    }

    pub fn vs_battle_setProjectionDistance(ctx: *zd.Ctx, arg0: anytype) void {
        _ = arg0;
        if (ctx.value(u1) == 1) v.g.vs_main_projectionDistance().* = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const t = ctx.alloc(v.vs_battle_cameraTransition_t);
    v.g.vs_battle_cameraTransition().* = t;
    const scratch = v.g.vs_scratch();

    const edges = [_]i32{ 0, 1, -1, 0xFFF, -0x1000, 0x1000, 0x7FFF_F000, -0x8000_0000, 0x7FFF_FFFF, 0x1234_5678 };
    scratch.camera.position.vy = ctx.pick(i32, &edges);
    scratch.camera.position.vx = ctx.int(i32);
    scratch.camera.position.vz = ctx.int(i32);
    const cur = scratch.camera.position.vy;

    t.direction.vy = ctx.pick(i32, &edges);
    t.transitionSpeed = ctx.pick(i32, &.{ 0, 1, 2, 0x1000, -1, 0x7FFF, 0x10000 });
    const next = cur +% t.direction.vy *% t.transitionSpeed;

    // Target Y: equal to the current or next Y up to the low 12 bits (so the masked
    // sides compare equal), random, or a little away from the current Y.
    t.targetPosition.vy = switch (ctx.range(u8, 0, 3)) {
        0 => cur ^ @as(i32, ctx.range(u12, 0, 0xFFF)),
        1 => next ^ @as(i32, ctx.range(u12, 0, 0xFFF)),
        2 => ctx.int(i32),
        else => cur +% ctx.range(i32, -0x3000, 0x3000),
    };

    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const scratch = v.g.vs_scratch();
    const t = v.g.vs_battle_cameraTransition().*.?;
    const cur = scratch.camera.position.vy & ~@as(i32, 0xFFF);
    const tgt = t.targetPosition.vy & ~@as(i32, 0xFFF);
    const nxt = (scratch.camera.position.vy +% t.direction.vy *% t.transitionSpeed) & ~@as(i32, 0xFFF);
    if (cur >= tgt and tgt >= nxt) return 0;
    if (tgt >= cur and nxt >= tgt) return 1;
    return 2;
}
