//! zig_diff spec: _checkFirstPersonViewExit -> check_first_person_view_exit.checkFirstPersonViewExit (146C.c).
//! Inputs: the button word (none of bits 6/10/11, each of them alone, all
//! together, sign bit set or clear, or random), and a camera transition in
//! the arena whose toSpherical yaw is drawn from edges around the 512 grid
//! (256, 768 and 0x7FFFFF00 make the C's comparison see equal sides; negative
//! yaws make the remainder negative; 0x7FFFFF80 overflows the rounding up).
//! The three callees are stubs that sometimes rewrite the yaw and the
//! position/lookAt vectors, so the C's read-back of the yaw sees both edge
//! values and callee-written ones.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").checkFirstPersonViewExit));

pub const classes = [_][:0]const u8{ "no-buttons", "yaw-above-256", "yaw-at-256", "yaw-at-or-below-255" };

const button_mask: u32 = (1 << 6) | (1 << 10) | (1 << 11);
const buttons = [_]u32{
    0,
    1 << 5,
    1 << 7,
    0x8000_0000,
    1 << 6,
    1 << 10,
    1 << 11,
    0xFFFF_FFFF,
    (1 << 6) | (1 << 10) | (1 << 11),
    0x7FFF_FFFF & ~button_mask,
};
const yaws = [_]i32{
    0,      1,          255,        256,        257,   511,  512,  -1,
    -255,   -256,       -257,       -512,       768,   -768, 0x7FFFFF80,
    0x7FFFFF00, -0x80000000, 0x7FFFFFFF, 1000, -1000,
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const trans = ctx.alloc(v.vs_battle_cameraTransition_t);
    v.g.vs_battle_cameraTransition().* = trans;
    v.g.vs_main_buttonsPressed().all = if (ctx.chance(4)) ctx.int(u32) else ctx.edge(u32, &buttons);
    trans.toSpherical.values.yaw = if (ctx.chance(2)) ctx.edge(i32, &yaws) else ctx.int(i32);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if ((v.g.vs_main_buttonsPressed().all & button_mask) == 0) return 0;
    const yaw = v.g.vs_battle_cameraTransition().*.?.toSpherical.values.yaw;
    const r = @rem(yaw, 512);
    if (r > 256) return 1;
    if (r == 256) return 2;
    return 3;
}

pub const stubs = struct {
    pub fn vs_battle_syncCameraAnglesFromPosition(ctx: *zd.Ctx, p: anytype) c_int {
        const s: *v._sphericalCamera = @ptrCast(@alignCast(p));
        if (ctx.value(u8) < 64) s.values.yaw = ctx.value(i32);
        return ctx.value(c_int);
    }

    pub fn _computeSphericalOffset(ctx: *zd.Ctx, pos: anytype, look: anytype, values: anytype) void {
        _ = values;
        if (ctx.value(u8) < 64) {
            const p: *v.VECTOR = @ptrCast(@alignCast(pos));
            p.vx = ctx.value(i32);
            p.vz = ctx.value(i32);
        }
        if (ctx.value(u8) < 64) {
            const l: *v.VECTOR = @ptrCast(@alignCast(look));
            l.vy = ctx.value(i32);
        }
    }

    pub fn _computeCameraTransition(ctx: *zd.Ctx, p: anytype) void {
        if (ctx.value(u8) < 64) {
            const q: *v.VECTOR = @ptrCast(@alignCast(p));
            q.vy = ctx.value(i32);
        }
    }
};
