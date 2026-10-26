//! zig_diff spec: vs_battle_setCameraLookAt -> set_camera_look_at.setCameraLookAt (146C.c).
//! Inputs: a VECTOR in the arena with each component an edge value (0, -1, 1,
//! the i32 extremes) half the time and any i32 otherwise, or the camera's own
//! lookAt (the self-copy alias, a quarter of the runs). The C has no branches
//! and no callees; the components and the aliased case catch a dropped,
//! swapped, narrowed or misdirected store.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setCameraLookAt));

pub const classes = [_][:0]const u8{ "separate", "aliased" };

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(4)) return .{&v.g.vs_scratch().camera.lookAt};
    const in = ctx.alloc(v.VECTOR);
    const edges = [_]i32{ 0, -1, 1, std.math.maxInt(i32), std.math.minInt(i32) };
    in.vx = ctx.pick(i32, &edges);
    in.vy = ctx.pick(i32, &edges);
    in.vz = ctx.pick(i32, &edges);
    in.pad = ctx.int(i32);
    return .{in};
}

pub fn classify(args: Args) usize {
    const p = args[0].?;
    return if (@intFromPtr(p) == @intFromPtr(&v.g.vs_scratch().camera.lookAt)) 1 else 0;
}
