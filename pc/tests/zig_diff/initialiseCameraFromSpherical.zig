//! zig_diff spec: vs_battle_initialiseCameraFromSpherical -> initialise_camera_from_spherical.initialiseCameraFromSpherical (146C.c).
//! Inputs: facing from a set of edges (-1 for the skip test, 0 for the signed
//! comparison's equal case, -8/-9/-16 for the +7 rounding, INT_MIN/INT_MAX for
//! wrapping) or any value; mode 1, 2 or other; the two output vectors either
//! distinct or aliased. The callee func_800A1108 writes the sp10 look-at
//! fields the C reads back, the clamp stub may rewrite the look-at, and the
//! offset stub writes the output position.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").initialiseCameraFromSpherical));

pub const classes = [_][:0]const u8{ "mode-1", "mode-2", "no-facing", "facing-negative", "facing-nonnegative" };

const facing_edges = [_]c_int{ -1, 0, 1, -2, -7, -8, -9, -16, 7, 8, 15, 16, -2147483648, 2147483647 };

pub fn prepare(ctx: *zd.Ctx) Args {
    const outPos = ctx.alloc(v.VECTOR);
    // Sometimes the caller passes the same vector for both outputs.
    const outLook = if (ctx.chance(4)) outPos else ctx.alloc(v.VECTOR);
    const facing = ctx.pick(c_int, &facing_edges);
    const mode = ctx.pick(c_int, &.{ 0, 1, 2, 3, -1 });
    return .{ outPos, outLook, facing, mode };
}

pub fn classify(args: Args) usize {
    if (args[3] == 1) return 0;
    if (args[3] == 2) return 1;
    if (args[2] == -1) return 2;
    if (args[2] < 0) return 3;
    return 4;
}

pub const stubs = struct {
    pub fn func_800A1108(ctx: *zd.Ctx, a: anytype, b: anytype) c_int {
        _ = a;
        // The callee fills the look-at position the C reads back.
        const sp: *v.func_8006EBF8_t = @ptrCast(@alignCast(@as(?*anyopaque, b).?));
        sp.unk0.unk4.vx = ctx.value(i16);
        sp.unk0.unk4.vy = ctx.value(i16);
        sp.unk0.unk4.vz = ctx.value(i16);
        return ctx.value(c_int);
    }

    pub fn _clampPositionToZoneBounds(ctx: *zd.Ctx, a: anytype, b: anytype) void {
        _ = b;
        // The real clamp may move the look-at point.
        const p: *v.VECTOR = @ptrCast(@alignCast(@as(?*anyopaque, a).?));
        if (ctx.value(u1) == 1) {
            p.vx = ctx.value(i32);
            p.vy = ctx.value(i32);
            p.vz = ctx.value(i32);
        }
    }

    pub fn _computeSphericalOffset(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) void {
        _ = b;
        _ = c;
        // The offset computation writes the output position.
        const p: *v.VECTOR = @ptrCast(@alignCast(@as(?*anyopaque, a).?));
        p.vx = ctx.value(i32);
        p.vy = ctx.value(i32);
        p.vz = ctx.value(i32);
    }
};
