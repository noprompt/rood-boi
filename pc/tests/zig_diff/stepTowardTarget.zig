//! zig_diff spec: _stepTowardTarget -> step_toward_target.stepTowardTarget (146C.c).
//! Inputs: a null or arena SVECTOR target, any transformFlag and maxSpeed (edge
//! and random values), and lookAt.vy at or around 0 and at 1, -1 and the i32
//! extremes. The three callees are recording stubs. _computeStepAndDisplacement
//! writes both out-vectors and returns zero or not (any sign). _addMinDelta and
//! _add_min write nothing and return 0 about one time in six, so lookAt.vy is
//! often exactly 0 after the stores, which covers the `> 0` test's equal side.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").stepTowardTarget));

pub const classes = [_][:0]const u8{
    "null-target-y-not-positive",
    "null-target-y-positive",
    "valid-target-y-not-positive",
    "valid-target-y-positive",
};

pub const stubs = struct {
    pub fn _computeStepAndDisplacement(
        ctx: *zd.Ctx,
        targetPos: anytype,
        step: anytype,
        displacement: anytype,
        transformFlag: anytype,
        maxSpeed: anytype,
    ) c_int {
        _ = targetPos;
        _ = transformFlag;
        _ = maxSpeed;
        // Both out-vectors are written on every call.
        const s: *v.VECTOR = @ptrCast(@alignCast(step));
        const d: *v.VECTOR = @ptrCast(@alignCast(displacement));
        s.vx = ctx.value(i32);
        s.vy = ctx.value(i32);
        s.vz = ctx.value(i32);
        d.vx = ctx.value(i32);
        d.vy = ctx.value(i32);
        d.vz = ctx.value(i32);
        // Zero about one call in three, otherwise any value (negative included).
        if (ctx.value(u8) < 85) return 0;
        return ctx.value(c_int);
    }

    pub fn _addMinDelta(ctx: *zd.Ctx, x: anytype, y: anytype, z: anytype) c_int {
        _ = x;
        _ = y;
        _ = z;
        if (ctx.value(u8) < 40) return 0;
        return ctx.value(c_int);
    }

    pub fn _add_min(ctx: *zd.Ctx, x: anytype, y: anytype, z: anytype) c_int {
        _ = x;
        _ = y;
        _ = z;
        if (ctx.value(u8) < 40) return 0;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const target: ?*v.SVECTOR = if (ctx.chance(4)) null else ctx.alloc(v.SVECTOR);
    const look = &v.g.vs_scratch().camera.lookAt;
    if (ctx.chance(4)) look.vy = 0;
    if (ctx.chance(3)) look.vy = ctx.pick(i32, &.{ 0, 1, -1, 2147483647, -2147483648 });
    const flag = ctx.pick(c_int, &.{ 0, 1, -1, 2147483647, -2147483648 });
    const speed = ctx.pick(c_int, &.{ 0, 1, -1, 32767, -32768 });
    return .{ target, flag, speed };
}

pub fn classify(args: Args) usize {
    const positive = v.g.vs_scratch().camera.lookAt.vy > 0;
    const base: usize = if (args[0] == null) 0 else 2;
    return base + @as(usize, @intFromBool(positive));
}
