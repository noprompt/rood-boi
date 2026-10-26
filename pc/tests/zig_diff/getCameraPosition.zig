//! zig_diff spec: vs_battle_getCameraPosition -> get_camera_position.getCameraPosition (146C.c).
//! Inputs: a fresh VECTOR in the arena for the out-parameter (the C never
//! tests it, so it is always non-null), and a random scratchpad-resident
//! camera whose position is biased toward zero, the sign extremes and
//! random values. The C has no branches and no ordered comparisons; it copies
//! three words, so the mutations are wrong sources, a dropped store and a
//! stray write to the out-parameter's padding.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getCameraPosition));

pub const classes = [_][:0]const u8{ "position-x-zero", "position-x-negative", "position-x-positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const out = ctx.alloc(v.VECTOR);
    const scratch = v.g.vs_scratch();
    scratch.camera.position.vx = ctx.pick(i32, &.{ 0, -1, 1, std.math.minInt(i32), std.math.maxInt(i32) });
    scratch.camera.position.vy = ctx.pick(i32, &.{ 0, -1, 1, std.math.minInt(i32), std.math.maxInt(i32) });
    scratch.camera.position.vz = ctx.pick(i32, &.{ 0, -1, 1, std.math.minInt(i32), std.math.maxInt(i32) });
    scratch.camera.lookAt.vz = ctx.int(i32);
    scratch.camera.farClip = ctx.int(i32);
    return .{out};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.vs_scratch().camera.position.vx;
    if (x == 0) return 0;
    if (x < 0) return 1;
    return 2;
}
