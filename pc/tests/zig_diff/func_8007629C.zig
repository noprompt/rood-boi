//! zig_diff spec: func_8007629C -> func_8007629C.func_8007629C (146C.c).
//! Inputs: an otag in the arena (DrawOTag only receives the pointer), and the
//! frame-buffer, timer and D_8004A52C globals at random. D_8004A52C takes the
//! edge values 0, 1, -1, INT_MIN, 2 and INT_MAX, so the pad loop is skipped
//! or entered, and its exits are both taken: a pressed 0x100 breaks it, and
//! the 0x800 toggle reaching zero breaks it too. The pad and timer calls
//! return any 32-bit value, and the pad read writes its reply byte into the
//! buffer it was given.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007629C));

pub const classes = [_][:0]const u8{ "no-pad-loop", "loop-d-negative", "loop-d-positive" };

pub const stubs = struct {
    /// The pad read writes its reply byte into the buffer it is given.
    pub fn vs_main_updatePadState(ctx: *zd.Ctx, port: anytype, buf: anytype) c_int {
        _ = port;
        buf[0] = ctx.value(u8);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const otag: [*c]c_uint = @ptrCast(@alignCast(ctx.allocBytes(64, 16)));
    const d = v.g.D_8004A52C();
    d.* = ctx.pick(i32, &.{ 0, 1, -1, std.math.minInt(i32), 2, std.math.maxInt(i32) });
    v.g.vs_gametime_tickspeed().* = ctx.pick(i32, &.{ 0, 1, -1, 2 });
    v.g.vs_main_frameBuf().* = ctx.pick(i32, &.{ 0, 1, -1, 2 });
    return .{otag};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_8004A52C().*;
    if (d == 0) return 0;
    return if (d < 0) 1 else 2;
}
