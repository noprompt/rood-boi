//! zig_diff spec: _isLookAtAtDestination -> is_look_at_at_destination.isLookAtAtDestination (146C.c).
//! Inputs: the camera's lookAt global and the position func_800A1108 reports (src, edge-biased so
//! vy*4096 + 0xFFFA6000 lands on 0 at src[1] = 90 and crosses the clamp at 91). Each lookAt
//! component is set to the expected position (with random low 12 bits, which the mask drops)
//! or left random, independently. The clamp stub either leaves the position alone (so the
//! pre-clamp vy clamp decides), writes the matching position, writes a partial match, or
//! writes random values. func_800A1108 can also rewrite the lookAt global it precedes.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").isLookAtAtDestination));

pub const classes = [_][:0]const u8{
    "clamp-stub-sets-match",
    "clamp-keeps-match",
    "clamp-keeps-match-vy-clamped",
    "clamp-stub-partial",
    "no-match",
};

/// Values func_800A1108 reports, set by prepare.
var src: [3]i16 = .{ 0, 0, 0 };
/// How _clampPositionToZoneBounds changes the position: 0 leaves it, 1 matches
/// lookAt, 2 matches x and z only, 3 writes random values.
var clamp_mode: u8 = 0;
/// The class prepare chose.
var kase: usize = 0;

pub fn prepare(ctx: *zd.Ctx) Args {
    const look: *v.VECTOR = &v.g.vs_scratch().camera.lookAt;
    src[0] = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 89, 90, 91 });
    src[1] = ctx.pick(i16, &.{ 0, 1, -1, 89, 90, 91, 32767, -32768 });
    src[2] = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    clamp_mode = ctx.range(u8, 0, 3);

    // The position the C computes before its clamp (0xFFFA6000 is -368640 as an int).
    const ex: i32 = @as(i32, src[0]) * 4096;
    const raw_y: i32 = @as(i32, src[1]) * 4096 +% -368640;
    const ey: i32 = if (raw_y > 0) 0 else raw_y;
    const ez: i32 = @as(i32, src[2]) * 4096;

    const mx = ctx.chance(2);
    const my = ctx.chance(2);
    const mz = ctx.chance(2);
    look.vx = if (mx) ex | @as(i32, ctx.int(u12)) else ctx.int(i32);
    look.vy = if (my) ey | @as(i32, ctx.int(u12)) else ctx.int(i32);
    look.vz = if (mz) ez | @as(i32, ctx.int(u12)) else ctx.int(i32);

    const all = mx and my and mz;
    kase = if (clamp_mode == 1)
        0
    else if (clamp_mode == 0 and all)
        (if (raw_y > 0) @as(usize, 2) else @as(usize, 1))
    else if (clamp_mode == 2)
        3
    else
        4;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return kase;
}

pub const stubs = struct {
    pub fn func_800A1108(ctx: *zd.Ctx, index: anytype, out: anytype) c_int {
        _ = index;
        const raw: ?*anyopaque = out;
        const o: *v.func_8006EBF8_t = @ptrCast(@alignCast(raw.?));
        o.unk0.unk4.vx = src[0];
        o.unk0.unk4.vy = src[1];
        o.unk0.unk4.vz = src[2];
        // The callee may rewrite the camera the C reads back after the clamp.
        if (clamp_mode == 3) v.g.vs_scratch().camera.lookAt.vz = ctx.value(i32);
        return ctx.value(c_int);
    }

    pub fn _clampPositionToZoneBounds(ctx: *zd.Ctx, pos: anytype, dst: anytype) void {
        _ = dst;
        const raw: ?*anyopaque = pos;
        const p: *v.VECTOR = @ptrCast(@alignCast(raw.?));
        const look = v.g.vs_scratch().camera.lookAt;
        switch (clamp_mode) {
            0 => {},
            1 => {
                p.vx = look.vx & ~@as(i32, 0xFFF);
                p.vy = look.vy & ~@as(i32, 0xFFF);
                p.vz = look.vz & ~@as(i32, 0xFFF);
            },
            2 => {
                p.vx = look.vx & ~@as(i32, 0xFFF);
                p.vz = look.vz & ~@as(i32, 0xFFF);
                p.vy = ctx.value(i32);
            },
            else => {
                p.vx = ctx.value(i32);
                p.vy = ctx.value(i32);
                p.vz = ctx.value(i32);
            },
        }
    }
};
