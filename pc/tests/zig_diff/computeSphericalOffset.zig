//! zig_diff spec: _computeSphericalOffset -> compute_spherical_offset.computeSphericalOffset (146C.c).
//! Inputs: three valid objects (an out VECTOR, a base VECTOR, a _sphericalValues
//! angles) with yaw, pitch, distance and base components drawn from edge values
//! (0, +-1, +-4096, the i32 extremes) or any i32. Either base or angles may alias
//! outPosition: the C overwrites outPosition->vx before it reads angles->yaw
//! again and before it reads basePosition->vx, so aliasing exposes store order.
//! The trig and normal calls are recording stubs. VectorNormal rewrites
//! outPosition with any values, as the real normalise does. rcos never returns 0
//! or -1, since the C divides by it and INT_MIN / -1 would fault.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").computeSphericalOffset));

pub const classes = [_][:0]const u8{ "distinct", "base-is-out", "angles-is-out" };

pub const stubs = struct {
    pub fn rsin(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        return ctx.value(c_int);
    }

    pub fn rcos(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        const r = ctx.value(c_int);
        return if (r == 0 or r == -1) 1 else r;
    }

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
    const out = ctx.alloc(v.VECTOR);
    const base = ctx.alloc(v.VECTOR);
    const sph = ctx.alloc(v._sphericalValues);
    const edges = [_]i32{ 0, 1, -1, 4096, -4096, 0x7fffffff, -0x80000000 };

    out.vx = ctx.int(i32);
    out.vy = ctx.int(i32);
    out.vz = ctx.int(i32);
    base.vx = ctx.pick(i32, &edges);
    base.vy = ctx.pick(i32, &edges);
    base.vz = ctx.pick(i32, &edges);
    sph.yaw = ctx.pick(i32, &edges);
    sph.pitch = ctx.pick(i32, &edges);
    sph.distance = ctx.pick(i32, &edges);
    sph.mode = ctx.int(i32);

    var base_ptr: *v.VECTOR = base;
    var angles_ptr: *v._sphericalValues = sph;
    if (ctx.chance(4)) {
        base_ptr = out;
    } else if (ctx.chance(4)) {
        angles_ptr = @ptrCast(out);
    }
    return .{ out, base_ptr, angles_ptr };
}

pub fn classify(args: Args) usize {
    if (args[1].? == args[0].?) return 1;
    if (@intFromPtr(args[2].?) == @intFromPtr(args[0].?)) return 2;
    return 0;
}
