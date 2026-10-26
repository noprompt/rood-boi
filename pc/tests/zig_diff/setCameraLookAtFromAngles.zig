//! zig_diff spec: _setCameraLookAtFromAngles -> set_camera_look_at_from_angles.setCameraLookAtFromAngles (146C.c).
//! Inputs: a _sphericalValues in the arena with yaw, pitch and distance drawn from
//! edge values (0, +-1, +-4096, the i32 extremes) and random bits, and mode random.
//! The C has no branches. rsin and rcos are stubbed to the PS1 sine-table range
//! (+-4096) and rcos is never zero, so the division cannot fault. VectorNormal is
//! a recording stub that writes its output vector, which the C reads back for the
//! distance multiply. Classes split on distance: zero, negative, small positive,
//! and large (where the product overflows i32).
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setCameraLookAtFromAngles));

pub const classes = [_][:0]const u8{ "distance-zero", "distance-negative", "distance-small", "distance-large" };

/// A PS1 sine-table value: -4096..4096.
fn tableValue(ctx: *zd.Ctx) c_int {
    return @as(c_int, ctx.value(u16) % 8193) - 4096;
}

pub const stubs = struct {
    pub fn rsin(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        return tableValue(ctx);
    }

    // The C divides by rcos(pitch): it must never be zero.
    pub fn rcos(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        const r = tableValue(ctx);
        return if (r == 0) 4096 else r;
    }

    // Real VectorNormal writes the normalised vector to v1; the C reads it back.
    pub fn VectorNormal(ctx: *zd.Ctx, v0: anytype, v1: anytype) c_int {
        _ = v0;
        const out: *v.VECTOR = @ptrCast(@alignCast(v1));
        out.vx = ctx.value(i32);
        out.vy = ctx.value(i32);
        out.vz = ctx.value(i32);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const sph = ctx.alloc(v._sphericalValues);
    sph.yaw = ctx.pick(i32, &.{ 0, 1, -1, 4096, -4096, 0x7fffffff, -0x80000000 });
    sph.pitch = ctx.pick(i32, &.{ 0, 1, -1, 4096, -4096, 0x7fffffff, -0x80000000 });
    sph.distance = ctx.pick(i32, &.{ 0, 1, -1, 256, 4096, 0x7fffffff, -0x80000000 });
    sph.mode = ctx.int(i32);
    return .{sph};
}

pub fn classify(args: Args) usize {
    const d = args[0].?.distance;
    if (d == 0) return 0;
    if (d < 0) return 1;
    if (d <= 4096) return 2;
    return 3;
}
