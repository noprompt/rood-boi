//! zig_diff spec: func_800D1B18 -> func_800D1B18.func_800D1B18 (5BF94.c).
//! Inputs: a D_800F54D8_t in the arena with random fields. The camera getters
//! are stubs: the position and look-at getters fill their out-parameters with
//! random values, the roll getter returns a random int (so the + 4096 * 8
//! addition wraps for large rolls), and the getters sometimes write the
//! globals the C reads after them (vs_main_nearClip from the look-at getter,
//! vs_scratch.camera.farClip from the roll getter). A port that reads those
//! globals before the calls, or skips a call, fails. The C has no branches,
//! so one input class covers every run.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D1B18));

pub const classes = [_][:0]const u8{"camera"};

pub const stubs = struct {
    pub fn vs_battle_getCameraPosition(ctx: *zd.Ctx, out: anytype) void {
        const p: *v.VECTOR = @ptrCast(@alignCast(out));
        p.vx = ctx.value(i32);
        p.vy = ctx.value(i32);
        p.vz = ctx.value(i32);
        p.pad = ctx.value(i32);
    }

    pub fn vs_battle_getCameraLookAt(ctx: *zd.Ctx, out: anytype) void {
        const p: *v.VECTOR = @ptrCast(@alignCast(out));
        p.vx = ctx.value(i32);
        p.vy = ctx.value(i32);
        p.vz = ctx.value(i32);
        p.pad = ctx.value(i32);
        // The C reads vs_main_nearClip after this call.
        if (ctx.value(u8) < 128) v.g.vs_main_nearClip().* = ctx.value(i32);
    }

    pub fn vs_battle_getCameraRoll(ctx: *zd.Ctx) c_int {
        // The C reads vs_scratch.camera.farClip after this call.
        if (ctx.value(u8) < 128) v.g.vs_scratch().camera.farClip = ctx.value(i32);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F54D8_t);
    return .{obj};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
