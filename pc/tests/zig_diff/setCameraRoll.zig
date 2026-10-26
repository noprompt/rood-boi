//! zig_diff spec: vs_battle_setCameraRoll -> set_camera_roll.setCameraRoll (146C.c).
//! Inputs: the roll argument as any c_int, drawn from edges (0, +-1, the 16-bit
//! and 32-bit extremes, 65536) or at random, over a scratchpad whose camera
//! angles start random. The C has no branches and no calls: the check is the
//! store into vs_scratch.camera.angles.vz, compared with the whole state.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setCameraRoll));

pub const classes = [_][:0]const u8{ "negative", "non-negative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    // Start the stored field from a random value, so a dropped store shows.
    v.g.vs_scratch().camera.angles.vz = ctx.int(i32);
    return .{ctx.pick(c_int, &.{
        0,
        1,
        -1,
        32767,
        -32768,
        65535,
        65536,
        -65536,
        std.math.maxInt(c_int),
        std.math.minInt(c_int),
    })};
}

pub fn classify(args: Args) usize {
    return if (args[0] < 0) 0 else 1;
}
