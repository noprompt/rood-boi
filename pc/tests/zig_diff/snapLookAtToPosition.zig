//! zig_diff spec: _snapLookAtToPosition -> snap_look_at_to_position.snapLookAtToPosition (146C.c).
//! Inputs: a VECTOR argument in the arena and a random camera lookAt in the
//! scratchpad-side global vs_scratch. The clamp call is a recording stub that
//! writes the out-parameter position (copied from a per-iteration target in
//! most runs, random components in others) and sometimes changes the camera
//! lookAt. The target is camera + delta per axis, so the lookAt deltas hit the
//! comparison edges (0x12000, -0x12000, 0x60000, -0x60000, 0) and their
//! neighbours (0x12001, -0x12001, ...), plus the i32 extremes, which wrap the
//! camera updates. At an exact equal edge the "> bound" and "snap to position"
//! outcomes coincide, so the boundary mutants use off-by-one constants instead,
//! which the neighbour deltas catch.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").snapLookAtToPosition));

pub const classes = [_][:0]const u8{
    "xhi-yhi", "xhi-ylo", "xhi-ymid",
    "xlo-yhi", "xlo-ylo", "xlo-ymid",
    "xmid-yhi", "xmid-ylo", "xmid-ymid",
};

const deltas = [_]i32{
    0,               1,               -1,
    0x12000,         0x12001,         0x11FFF,
    -0x12000,        -0x12001,        -0x11FFF,
    0x60000,         0x60001,         0x5FFFF,
    -0x60000,        -0x60001,        -0x5FFFF,
    std.math.maxInt(i32), std.math.minInt(i32),
};

const cams = [_]i32{
    0,      1,                  -1,
    0x12000, -0x12000,          0x60000,
    -0x60000, std.math.maxInt(i32), std.math.minInt(i32),
};

// Per-iteration choices, set by prepare and read by the stub and classify.
var want: v.VECTOR = std.mem.zeroes(v.VECTOR);
var dx: i32 = 0;
var dy: i32 = 0;

pub const stubs = struct {
    pub fn _clampPositionToZoneBounds(ctx: *zd.Ctx, a: anytype, b: anytype) void {
        _ = a;
        const out: *v.VECTOR = @ptrCast(@alignCast(b));
        if (ctx.value(u8) < 200) {
            out.* = want;
        } else {
            out.vx = ctx.value(i32);
            out.vy = ctx.value(i32);
            out.vz = ctx.value(i32);
        }
        // The callee may move the camera; the C reads lookAt after the call.
        if (ctx.value(u8) < 40) v.g.vs_scratch().camera.lookAt.vx = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.alloc(v.VECTOR);
    const sc = v.g.vs_scratch();

    const camX = ctx.pick(i32, &cams);
    const camY = ctx.pick(i32, &cams);
    const camZ = ctx.pick(i32, &cams);
    sc.camera.lookAt.vx = camX;
    sc.camera.lookAt.vy = camY;
    sc.camera.lookAt.vz = camZ;

    dx = ctx.pick(i32, &deltas);
    dy = ctx.pick(i32, &deltas);
    const dz = ctx.pick(i32, &deltas);

    want = .{
        .vx = camX +% dx,
        .vy = camY +% dy,
        .vz = camZ +% dz,
        .pad = ctx.int(i32),
    };
    return .{arg};
}

fn xClass(d: i32) usize {
    if (d > 0x12000) return 0;
    if (d < -0x12000) return 1;
    return 2;
}

fn yClass(d: i32) usize {
    if (d > 0x60000) return 0;
    if (d < -0x60000) return 1;
    return 2;
}

pub fn classify(args: Args) usize {
    _ = args;
    return xClass(dx) * 3 + yClass(dy);
}
