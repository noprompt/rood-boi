//! zig_diff spec: func_8006E158 -> func_8006E158.func_8006E158 (146C.c).
//! Inputs: the camera's spherical state (yaw, pitch, distance, mode, the
//! turn in progress, the zoom clamps, unk24) and the button and lock globals
//! (D_800F196C, _cameraMode, the pressed and previous button words). The turn
//! is set up so its yaw comparisons see both sides equal: the step by distance
//! lands yaw exactly on pitch, pitch +/- 0x78 or pitch +/- 0x79 (the last one
//! is where a `<=` against `+ 0x79` differs). Zoom distance is set at the
//! 0x600, 0x900 and initialDistance +/- 0xA0 edges, unk24 at +/-16, +/-64 and
//! their step neighbours. The two right-stick hooks are recording stubs that
//! rewrite the camera through the pointer they are given, but only on about
//! one call in eight, so the prepared equalities survive to the comparisons.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006E158));

pub const classes = [_][:0]const u8{ "locked", "turning", "mode0", "mode2", "mode-other" };

pub const stubs = struct {
    pub fn pc_camera_stick_tick(ctx: *zd.Ctx, p: anytype, locked: anytype) void {
        _ = locked;
        const cam: *v._sphericalCamera = @ptrCast(@alignCast(p));
        if (ctx.value(u3) != 0) return; // most calls leave the camera as prepare set it
        cam.delta.yaw = ctx.value(u2);
        cam.values.yaw = @as(i32, ctx.value(u12)) - 0x800;
        cam.delta.distance = ctx.value(u6);
        cam.delta.mode = ctx.value(u2);
        cam.unk24 = @as(i32, ctx.value(i8));
        cam.delta.pitch = @as(i32, ctx.value(i16));
    }

    pub fn pc_camera_stick_turn(ctx: *zd.Ctx, p: anytype) void {
        const cam: *v._sphericalCamera = @ptrCast(@alignCast(p));
        if (ctx.value(u3) != 0) return;
        cam.values.yaw = @as(i32, ctx.value(u12)) - 0x800;
        cam.delta.pitch = @as(i32, ctx.value(i16));
        cam.delta.yaw = 0;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F196C().* = ctx.pick(u32, &.{ 0, 1, 2, 3, 4 });
    v.g._cameraMode().* = ctx.pick(u32, &.{ 3, 4, 10, 11, 12 });
    v.g.vs_main_buttonsPreviousState().* = ctx.pick(i32, &.{ 0, 4, 8, 12, 1, 5, 9 });
    v.g.vs_main_buttonsPressed().all = ctx.pick(u32, &.{ 0, 0x100, 0x200, 0xFFFF_FFFF });

    const cam = v.g.vs_battle_cameraCurrentSpherical();
    cam.delta.yaw = ctx.edge(i32, &.{ 0, 0, 0, 1, 2, 1, 2, 3 });
    cam.delta.mode = ctx.edge(i32, &.{ 0, 1, 2, 3, -1, 4, 0, 2 });
    cam.delta.distance = ctx.edge(i32, &.{ 0, 7, 8, 9, 16, 32, 39, 40, 41, -8 });
    cam.delta.pitch = ctx.range(i32, -8, 8) * 0x200;

    // The turn steps yaw by distance (-= for yaw 1, += for yaw 2) before its
    // comparisons, so the yaw handed in is the target the compare must see,
    // moved back by one step. Targets: pitch +/- 0x78, +/- 0x79, pitch.
    const d = cam.delta.distance;
    const p = cam.delta.pitch;
    const dir: i32 = if (cam.delta.yaw == 2) -1 else 1;
    const target: i32 = switch (ctx.range(u8, 0, 5)) {
        0 => p + 0x78,
        1 => p + 0x79,
        2 => p,
        3 => p - 0x78,
        4 => p - 0x79,
        else => ctx.range(i32, -0x1000, 0x1000),
    };
    cam.values.yaw = target + dir * d;

    cam.initialDistance = ctx.pick(i32, &.{ 0x600, 0x900, 0x500, 0x700, 0x600 + 0xA0 });
    const id = cam.initialDistance;
    cam.values.distance = switch (ctx.range(u8, 0, 9)) {
        0 => 0x600,
        1 => 0x5FF,
        2 => 0x601,
        3 => 0x900,
        4 => 0x8FF,
        5 => 0x901,
        6 => id,
        7 => id + 0xA0,
        8 => id - 0xA0,
        else => ctx.range(i32, 0, 0x1000),
    };

    cam.unk24 = ctx.edge(i32, &.{ -16, 16, -15, 15, -1, -8, 0, -63, -64, 64, 63, -17, 17, -80, 80, 48, -48, 32, -32 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F196C().*;
    const m = v.g._cameraMode().*;
    if (d == 3 or (d == 2 and (m == 4 or m == 11))) return 0;
    const cam = v.g.vs_battle_cameraCurrentSpherical();
    if (cam.delta.yaw != 0) return 1;
    return switch (cam.delta.mode) {
        0 => 2,
        2 => 3,
        else => 4,
    };
}
