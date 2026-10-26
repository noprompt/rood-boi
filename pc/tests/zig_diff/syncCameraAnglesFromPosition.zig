//! zig_diff spec: vs_battle_syncCameraAnglesFromPosition -> sync_camera_angles_from_position.syncCameraAnglesFromPosition (146C.c).
//! Inputs: the optional camera object (null, or an arena object whose bytes are
//! random), and the scratchpad camera's position and lookAt globals. Each axis
//! is sometimes equal to lookAt, sometimes within 4095 of it (so the /4096 delta
//! is zero), sometimes an edge value, and otherwise random within +-0x3f000000
//! so no subtraction or square overflows. VectorNormal writes nonzero normalized
//! components whenever the input component is nonzero (the distance divisions
//! never see zero), and the ratan2 and SquareRoot12 stubs return values in
//! about +-2^23, so the yaw wrap sees negative values below -4096.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").syncCameraAnglesFromPosition));

pub const classes = [_][:0]const u8{ "no-camera", "x-offset", "z-offset", "on-look-at" };

fn setAxis(ctx: *zd.Ctx, pos: *i32, look: *i32) void {
    pos.* = if (ctx.chance(4))
        ctx.edge(i32, &.{ 0, 1, -1, 4095, -4095, 4096, -4096 })
    else
        ctx.range(i32, -0x3f00_0000, 0x3f00_0000);
    if (ctx.chance(3)) {
        look.* = pos.*;
    } else if (ctx.chance(2)) {
        look.* = pos.* + ctx.range(i32, -4095, 4095);
    } else {
        look.* = ctx.range(i32, -0x3f00_0000, 0x3f00_0000);
    }
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const scratch = v.g.vs_scratch();
    const cam = &scratch.camera;
    setAxis(ctx, &cam.position.vx, &cam.lookAt.vx);
    setAxis(ctx, &cam.position.vy, &cam.lookAt.vy);
    setAxis(ctx, &cam.position.vz, &cam.lookAt.vz);
    if (ctx.chance(4)) return .{null};
    const obj = ctx.alloc(v._sphericalCamera);
    return .{obj};
}

fn axisDelta(p: i32, l: i32) i32 {
    return @divTrunc(p - l, 4096);
}

pub fn classify(args: Args) usize {
    if (args[0] == null) return 0;
    const cam = &v.g.vs_scratch().camera;
    if (axisDelta(cam.position.vx, cam.lookAt.vx) != 0) return 1;
    if (axisDelta(cam.position.vz, cam.lookAt.vz) != 0) return 2;
    return 3;
}

fn normComponent(ctx: *zd.Ctx, input: i32) i32 {
    const r = @rem(ctx.value(i32), 40000);
    if (input == 0) return 0;
    return if (r == 0) 1 else r;
}

fn smallValue(ctx: *zd.Ctx) c_int {
    return @as(c_int, ctx.value(i32) >> 8);
}

pub const stubs = struct {
    pub fn VectorNormal(ctx: *zd.Ctx, v0: anytype, v1: anytype) c_int {
        const src: *const v.VECTOR = @ptrCast(@alignCast(v0));
        const dst: *v.VECTOR = @ptrCast(@alignCast(v1));
        dst.vx = normComponent(ctx, src.vx);
        dst.vy = normComponent(ctx, src.vy);
        dst.vz = normComponent(ctx, src.vz);
        return ctx.value(c_int);
    }

    pub fn SquareRoot12(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        return smallValue(ctx);
    }

    pub fn ratan2(ctx: *zd.Ctx, y: anytype, x: anytype) c_int {
        _ = y;
        _ = x;
        return smallValue(ctx);
    }
};
