//! zig_diff spec: vs_battle_setCameraPosition -> set_camera_position.setCameraPosition (146C.c).
//! Inputs: one VECTOR in the arena whose x, y and z are random i32 values,
//! often edge values (0, -1, the i32 extremes, 16-bit wrap points) so a
//! narrowing or a swapped field shows, and sometimes all zero. The C has
//! no branches and no callees; it copies the three components into
//! vs_scratch.camera.position and never touches the pad or lookAt.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setCameraPosition));

pub const classes = [_][:0]const u8{ "zero-vector", "random-vector" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const edges = [_]i32{ 0, 1, -1, 32767, 32768, -32768, -32769, 65535, 65536, std.math.maxInt(i32), std.math.minInt(i32) };
    const pos = ctx.alloc(v.VECTOR);
    if (ctx.chance(4)) {
        pos.vx = 0;
        pos.vy = 0;
        pos.vz = 0;
    } else {
        pos.vx = ctx.pick(i32, &edges);
        pos.vy = ctx.pick(i32, &edges);
        pos.vz = ctx.pick(i32, &edges);
    }
    pos.pad = ctx.int(i32);
    return .{pos};
}

pub fn classify(args: Args) usize {
    const p = args[0].?;
    return if (p.vx == 0 and p.vy == 0 and p.vz == 0) 0 else 1;
}
