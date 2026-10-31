//! zig_diff spec: func_80074050 -> func_80074050.func_80074050 (146C.c).
//! Inputs: a random _mpdRoomSectionA in the arena whose two coordinates come
//! from edge values across i16, so `(coord << 7) + 0x40` narrowed to a short
//! wraps outside -256..255, and an arg1 from edge values. D_800F19CC points at
//! one of two arena objects, and the callees move that global between them,
//! so the C's final two stores must go through whichever object is current
//! after func_8009E070. The shorts the C passes to func_8009E070 are copied
//! into an arena object, so their contents reach the compared state. The C's
//! only branch is the loop, which always runs 16 times.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80074050));

pub const classes = [_][:0]const u8{ "in-range", "negative", "wraps" };

var orig_cam: *v.D_800F19CC_t = undefined;
var alt_cam: *v.D_800F19CC_t = undefined;
var cap: *[2]c_short = undefined;
var use_alt: bool = false;

/// Points D_800F19CC at one of the two prepared objects, drawn by ctx.value.
fn pickCam(ctx: *zd.Ctx) void {
    v.g.D_800F19CC().* = if (ctx.value(u1) == 1) alt_cam else orig_cam;
}

pub const stubs = struct {
    pub fn func_8006EF10(ctx: *zd.Ctx) void {
        _ = ctx;
        if (use_alt) v.g.D_800F19CC().* = alt_cam;
    }

    pub fn func_800A1108(ctx: *zd.Ctx, a: anytype, p: anytype) c_int {
        _ = a;
        const t: *v.func_8006EBF8_t = @ptrCast(@alignCast(p.?));
        t.unk0.unk0.value = ctx.value(i32);
        return ctx.value(c_int);
    }

    pub fn func_8009E5C4(ctx: *zd.Ctx, i: anytype) void {
        _ = i;
        if (ctx.value(u8) < 64) pickCam(ctx);
    }

    pub fn func_8009E070(ctx: *zd.Ctx, a: anytype, p: anytype, b: anytype) void {
        _ = a;
        _ = b;
        // The C's sp10 is a stack array: copy the two coordinates it passes
        // into the arena so a wrong value shows in the compared state.
        const s: [*]const c_short = @ptrCast(@alignCast(p));
        cap.* = .{ s[0], s[2] };
        if (ctx.value(u1) == 1) pickCam(ctx);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = ctx.alloc(v._mpdRoomSectionA);
    const edges = [_]i16{ 0, -1, 1, 127, 128, 255, 256, -256, -257, 32767, -32768 };
    room.unk0.unk0 = ctx.pick(i16, &edges);
    room.unk0.unk2 = ctx.pick(i16, &edges);

    orig_cam = ctx.alloc(v.D_800F19CC_t);
    alt_cam = ctx.alloc(v.D_800F19CC_t);
    cap = ctx.alloc([2]c_short);
    use_alt = ctx.chance(2);
    v.g.D_800F19CC().* = orig_cam;

    return .{ room, ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFFFFFF, -0x80000000 }) };
}

pub fn classify(args: Args) usize {
    const room = args[0].?;
    const x = room.unk0.unk0;
    const y = room.unk0.unk2;
    if (x < -256 or x > 255 or y < -256 or y > 255) return 2;
    if (x < 0 or y < 0) return 1;
    return 0;
}
