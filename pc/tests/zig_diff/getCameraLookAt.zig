//! zig_diff spec: vs_battle_getCameraLookAt -> get_camera_look_at.getCameraLookAt (146C.c).
//! Inputs: the output VECTOR is a fresh arena object (its bytes random, so the
//! pad word the C never writes must survive), or it aliases the scratchpad's
//! own camera.lookAt (the copy then changes nothing). The C has no branches;
//! the scratchpad global is random bytes filled by the harness.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getCameraLookAt));

pub const classes = [_][:0]const u8{ "fresh-out", "alias-lookAt" };

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(4)) {
        return .{&v.g.vs_scratch().camera.lookAt};
    }
    const out = ctx.alloc(v.VECTOR);
    return .{out};
}

pub fn classify(args: Args) usize {
    const out = args[0].?;
    return if (@intFromPtr(out) == @intFromPtr(&v.g.vs_scratch().camera.lookAt)) 1 else 0;
}
