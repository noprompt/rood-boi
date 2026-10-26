//! zig_diff spec: vs_battle_setNearClip -> set_near_clip.setNearClip (146C.c).
//! Inputs: an arbitrary c_int, with edges (0, -1, 1, the i16 and i32 extremes,
//! 0x8000, 0x10000) picked half the time. The C has no branches, so the
//! classes only name the sign of the value; the stored global and the call's
//! argument are compared in every run, and the state hash at the call catches
//! a store moved after it.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setNearClip));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.pick(c_int, &.{ 0, -1, 1, 0x7FFF, -0x8000, 0x8000, 0x10000, std.math.maxInt(c_int), std.math.minInt(c_int) })};
}

pub fn classify(args: Args) usize {
    const x = args[0];
    if (x < 0) return 0;
    if (x == 0) return 1;
    return 2;
}
