//! zig_diff spec: func_800D52A4 -> func_800D52A4.func_800D52A4 (5BF94.c).
//! Inputs: a head pointer that is null (about one in six runs) or a chain of
//! 1-3 effectMotionState nodes in the arena. Each node has a mass (unk8, never
//! 0 and never -1: it is the divisor, and INT_MIN / -1 traps on x86), random or
//! near-edge velocities, forces, positions, gravity and attraction (zero about
//! one time in four). Quiet runs zero the velocities, forces and gravity, so x
//! stays put and the attraction target is set to x>>12 plus a small delta per
//! axis: that reaches the all-zero direction path and every partial match of
//! the `||`. Loud runs give random targets, so every direction component is
//! nonzero on its own. VectorNormal is a recording stub that writes the
//! direction back (random, shifted) and returns a value, as the real callee does.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D52A4));

pub const classes = [_][:0]const u8{
    "null-head",
    "no-attraction",
    "attraction-on-target",
    "attraction-moving",
};

/// The class of the head node, set by prepare and read by classify.
var kind: usize = 0;

pub const stubs = struct {
    pub fn VectorNormal(ctx: *zd.Ctx, v0: anytype, v1: anytype) c_int {
        _ = v0;
        // The real callee normalises the vector in place: the C reads it back.
        const out: *v.VECTOR = @ptrCast(@alignCast(v1));
        out.vx = ctx.value(i32) >> ctx.value(u5);
        out.vy = ctx.value(i32) >> ctx.value(u5);
        out.vz = ctx.value(i32) >> ctx.value(u5);
        return ctx.value(c_int);
    }
};

fn nonzeroI32(ctx: *zd.Ctx) i32 {
    const x = ctx.pick(i32, &.{ 1, -1, 4096, -4096, 0x7fffffff, -0x7fffffff - 1, 0x12345 });
    return if (x == 0) 1 else x;
}

fn matchDelta(ctx: *zd.Ctx) i16 {
    if (ctx.chance(2)) return 0;
    return ctx.edge(i16, &.{ 1, -1, 2 });
}

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(6)) {
        kind = 0;
        return .{null};
    }
    const quiet = ctx.chance(3);
    const count = ctx.range(usize, 1, 3);
    var nodes: [3]*v.func_800D2904_t = undefined;
    for (0..count) |i| nodes[i] = ctx.alloc(v.func_800D2904_t);

    v.g.D_800F5618().* = ctx.pick(i32, &.{ 0, 1, -1, 100, 0x7fffffff, -0x80000000 });
    const gravity = v.g.D_800F5620();
    if (quiet) {
        gravity.* = .{ .unk0 = 0, .unk4 = 0, .unk8 = 0, .unkC = 0 };
    } else {
        gravity.unk0 = ctx.pick(i32, &.{ 0, 1, -1, 4096, -4096 });
        gravity.unk4 = ctx.pick(i32, &.{ 0, 1, -1, 4096, -4096 });
        gravity.unk8 = ctx.pick(i32, &.{ 0, 1, -1, 4096, -4096 });
    }

    var head_kind: usize = 0;
    for (0..count) |i| {
        const node = nodes[i];
        // Never 0 (the divisor) and never -1: with a numerator of INT_MIN
        // the C's division would trap (INT_MIN / -1).
        var mass = ctx.pick(i16, &.{ 1, 2, -2, 4096, -4096, 32767, -32768 });
        if (mass == 0 or mass == -1) mass = 1;
        node.unk8 = mass;

        const st: *v.effectMotionState = @ptrFromInt(@intFromPtr(node) + 8);
        st.gravityScale = ctx.pick(i16, &.{ 0, 1, -1, 4096, 32767, -32768 });
        st.ax = ctx.int(i32);
        st.ay = ctx.int(i32);
        st.az = ctx.int(i32);

        const at: *v.effectAttractionView = @ptrCast(node);
        at.attraction = if (ctx.chance(4)) 0 else nonzeroI32(ctx);

        var zero = false;
        if (quiet) {
            st.vx = 0;
            st.vy = 0;
            st.vz = 0;
            st.fx = 0;
            st.fy = 0;
            st.fz = 0;
            st.x = ctx.range(i32, -9000, 9000);
            st.y = ctx.range(i32, -9000, 9000);
            st.z = ctx.range(i32, -9000, 9000);
            const dx = matchDelta(ctx);
            const dy = matchDelta(ctx);
            const dz = matchDelta(ctx);
            at.targetX = @as(i16, @truncate(st.x >> 12)) +% dx;
            at.targetY = @as(i16, @truncate(st.y >> 12)) +% dy;
            at.targetZ = @as(i16, @truncate(st.z >> 12)) +% dz;
            zero = dx == 0 and dy == 0 and dz == 0;
        } else {
            st.vx = ctx.pick(i32, &.{ 0, 1, -1, 4096, 0x7fffffff, -0x80000000 });
            st.vy = ctx.pick(i32, &.{ 0, 1, -1, 4096, 0x7fffffff, -0x80000000 });
            st.vz = ctx.pick(i32, &.{ 0, 1, -1, 4096, 0x7fffffff, -0x80000000 });
            st.fx = ctx.pick(i32, &.{ 0, 1, -1, 0x7ffff, -0x7ffff });
            st.fy = ctx.pick(i32, &.{ 0, 1, -1, 0x7ffff, -0x7ffff });
            st.fz = ctx.pick(i32, &.{ 0, 1, -1, 0x7ffff, -0x7ffff });
            st.x = ctx.pick(i32, &.{ 0, 4095, 4096, -4096, -1, 0x7fffffff, -0x80000000 });
            st.y = ctx.pick(i32, &.{ 0, 4095, 4096, -4096, -1, 0x7fffffff, -0x80000000 });
            st.z = ctx.pick(i32, &.{ 0, 4095, 4096, -4096, -1, 0x7fffffff, -0x80000000 });
            at.targetX = ctx.pick(i16, &.{ 0, 1, -1, 0x7fff, -0x8000 });
            at.targetY = ctx.pick(i16, &.{ 0, 1, -1, 0x7fff, -0x8000 });
            at.targetZ = ctx.pick(i16, &.{ 0, 1, -1, 0x7fff, -0x8000 });
        }

        if (i == 0) {
            head_kind = if (at.attraction == 0) 1 else if (quiet and zero) 2 else 3;
        }

        const nxt: ?*v.func_800D2904_t = if (i + 1 < count) nodes[i + 1] else null;
        psx.put(&node.next, nxt);
    }

    kind = head_kind;
    return .{nodes[0]};
}

pub fn classify(args: Args) usize {
    _ = args;
    return kind;
}
