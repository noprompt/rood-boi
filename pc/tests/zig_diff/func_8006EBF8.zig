//! zig_diff spec: func_8006EBF8 -> func_8006EBF8.func_8006EBF8 (146C.c).
//! Inputs: D_800F1968 zero and nonzero (1, -1, the i32 extremes), and the three
//! sp10 position fields drawn from edge values (0, +-1, i16 extremes), so the
//! shift and the 0xFFFA6000 offset see every sign. func_800A1108's stub writes
//! the three fields the C reads back. The position passed to
//! _snapLookAtToPosition is a stack local, so the snap stub moves it by ctx
//! values and copies it into the camera's angles; the following
//! _setCameraPositionFromAngles call hashes that global, which is how every
//! position value (and so each mutation of it) reaches the compared state.
//! The C returns `v`, which it never assigns, so the return value is whatever
//! GCC leaves in the return register; the spec compares it as the harness finds it.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006EBF8));

pub const classes = [_][:0]const u8{ "init-zero", "init-nonzero" };

/// The three fields func_800A1108's stub writes into sp10, set by prepare.
var fill: [3]i16 = .{ 0, 0, 0 };

pub const stubs = struct {
    pub fn func_800A4D8C(ctx: *zd.Ctx) void {
        // The real init may set the init flag; the C does not read it back,
        // but the draw keeps both outcomes in the trace.
        if (ctx.value(u1) == 1) v.g.D_800F1968().* = ctx.value(i32);
    }

    pub fn func_800A1108(ctx: *zd.Ctx, index: c_int, out: ?*anyopaque) c_int {
        _ = index;
        const t: *v.func_8006EBF8_t = @ptrCast(@alignCast(out.?));
        t.unk0.unk4.vx = fill[0];
        t.unk0.unk4.vy = fill[1];
        t.unk0.unk4.vz = fill[2];
        return ctx.value(c_int);
    }

    pub fn _snapLookAtToPosition(ctx: *zd.Ctx, p: anytype) void {
        // The snap moves the position it was given (wrapping, by a ctx value)
        // and points the camera's angles at it, so the position the C built
        // is visible in the camera global that the next call hashes.
        const pos: *v.VECTOR = @ptrCast(@alignCast(p));
        pos.vx +%= ctx.value(i32);
        pos.vy +%= ctx.value(i32);
        pos.vz +%= ctx.value(i32);
        const cam = v.g.vs_battle_cameraCurrentSpherical();
        cam.values.yaw = pos.vx;
        cam.values.pitch = pos.vy;
        cam.values.distance = pos.vz;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F1968().* = ctx.pick(i32, &.{ 0, 1, -1, std.math.minInt(i32), std.math.maxInt(i32) });
    fill[0] = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    fill[1] = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    fill[2] = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F1968().* == 0) 0 else 1;
}
