//! zig_diff spec: _setCameraPositionFromAngles -> set_camera_position_from_angles.setCameraPositionFromAngles (146C.c).
//! Inputs: a null spherical pointer, an arbitrary arena spherical block, or the
//! game's own vs_battle_cameraCurrentSpherical.values (the only pointer the C
//! hands to the right-stick hook). The camera's sphere values are edge-biased
//! (zero, -1, extremes). The right-stick hook and the offset computation are
//! recording stubs that write what the real callees write: the hook rewrites the
//! copy it is given from the look-at vector, and the offset computation writes
//! the camera position from the look-at vector and the sphere it is passed.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setCameraPositionFromAngles));

pub const classes = [_][:0]const u8{ "null-spherical", "camera-spherical", "other-spherical" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const cam = v.g.vs_battle_cameraCurrentSpherical();
    cam.values.yaw = ctx.pick(i32, &.{ 0, -1, 4096, std.math.maxInt(i32), std.math.minInt(i32) });
    cam.values.pitch = ctx.pick(i32, &.{ 0, -1, 1024, std.math.maxInt(i32), std.math.minInt(i32) });
    cam.values.distance = ctx.pick(i32, &.{ 0, 1, -1, 1000 });
    cam.values.mode = ctx.pick(i32, &.{ 0, 1, -1 });

    const own = ctx.alloc(v._sphericalValues);
    own.* = .{
        .yaw = ctx.int(i32),
        .pitch = ctx.int(i32),
        .distance = ctx.int(i32),
        .mode = ctx.int(i32),
    };

    const choice = ctx.range(u8, 0, 7);
    const sph: ?*v._sphericalValues = switch (choice) {
        0...1 => null,
        2...4 => &cam.values,
        else => own,
    };
    return .{sph};
}

pub fn classify(args: Args) usize {
    const sph = args[0] orelse return 0;
    if (sph == &v.g.vs_battle_cameraCurrentSpherical().values) return 1;
    return 2;
}

pub const stubs = struct {
    /// The right-stick hook: rewrites the copy from the look-at vector and a value.
    pub fn pc_camera_stick_place(ctx: *zd.Ctx, p: anytype, look: anytype) void {
        const s: *v._sphericalValues = @ptrCast(@alignCast(p));
        const l: *const v.VECTOR = @ptrCast(@alignCast(look));
        s.yaw = ctx.value(i32);
        s.pitch = l.vy +% ctx.value(i32);
        s.distance = l.vz;
        s.mode = ctx.value(i32);
    }

    /// The offset computation: writes the camera position from the look-at
    /// vector and the sphere it is passed (its real effect on the camera).
    pub fn _computeSphericalOffset(ctx: *zd.Ctx, pos: anytype, look: anytype, sph: anytype) void {
        const p: *v.VECTOR = @ptrCast(@alignCast(pos));
        const l: *const v.VECTOR = @ptrCast(@alignCast(look));
        p.vx = l.vx +% ctx.value(i32);
        p.vy = l.vy;
        p.vz = l.vz +% ctx.value(i32);
        p.pad = ctx.value(i32);
        if (@intFromPtr(sph) != 0) {
            const s: *const v._sphericalValues = @ptrCast(@alignCast(sph));
            p.vy +%= s.pitch;
            p.vz +%= s.distance;
            p.pad +%= s.yaw ^ s.mode;
        }
    }
};
