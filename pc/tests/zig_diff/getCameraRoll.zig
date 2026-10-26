//! zig_diff spec: vs_battle_getCameraRoll -> get_camera_roll.getCameraRoll (146C.c).
//! The C has no branches: it returns vs_scratch.camera.angles.vz & 0xFFF. The
//! inputs set that field (random bytes elsewhere in the scratch state) to edges
//! around the 12-bit mask and the i32 extremes, so both the sign-clear and the
//! sign-set halves of the field are exercised. Nothing is called.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getCameraRoll));

pub const classes = [_][:0]const u8{ "sign-clear", "sign-set" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const s = v.g.vs_scratch();
    s.camera.angles.vz = ctx.pick(i32, &.{
        0,
        -1,
        0xFFF,
        0x1000,
        0x7FF,
        std.math.minInt(i32),
        std.math.maxInt(i32),
    });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.vs_scratch().camera.angles.vz < 0) 1 else 0;
}
