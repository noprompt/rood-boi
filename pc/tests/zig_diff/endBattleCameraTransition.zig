//! zig_diff spec: _endBattleCameraTransition -> end_battle_camera_transition.endBattleCameraTransition (146C.c).
//! Inputs: a transition object in the arena (random bytes, so the copied
//! camera, spherical state and clip values are arbitrary), with the
//! transition global set to it on entry (the C dereferences it first, so it
//! is never null on entry). The setNearClip stub writes the object's
//! fromProjectionDistance, which the C reads back after that call. The
//! setProjectionDistance stub is the last callee that reads the object, so
//! it may clear the global, as the real callee may: `clear_at` picks, per
//! iteration, whether it does. The two classes are "kept" and
//! "cleared-by-projection-distance", covering the final null test both ways.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").endBattleCameraTransition));

pub const classes = [_][:0]const u8{ "kept", "cleared-by-projection-distance" };

/// Whether setProjectionDistance clears the transition global this iteration.
/// Set by prepare, so both runs see the same choice.
var clear_at: u8 = 0;

pub const stubs = struct {
    pub fn vs_battle_setNearClip(ctx: *zd.Ctx, x: anytype) void {
        _ = x;
        if (v.g.vs_battle_cameraTransition().*) |t| {
            t.fromProjectionDistance = ctx.value(i32);
        }
    }

    pub fn vs_battle_setProjectionDistance(ctx: *zd.Ctx, x: anytype) void {
        _ = ctx;
        _ = x;
        if (clear_at == 1) v.g.vs_battle_cameraTransition().* = null;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const t = ctx.alloc(v.vs_battle_cameraTransition_t);
    v.g.vs_battle_cameraTransition().* = t;
    clear_at = ctx.range(u8, 0, 1);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return clear_at;
}
