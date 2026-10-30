//! zig_diff spec: func_8008F30C -> func_8008F30C.func_8008F30C (146C.c).
//! Inputs: arg0 is the element count: negative (including values below -32768
//! so the i16 store wraps), zero, a few elements, or 256 and up. arg1 is any
//! int whose low byte is stored. D_800F1DD4 points at an arena block of
//! max(arg0, 0) + 1 sixteen-byte elements, so every element the loop writes is
//! owned memory. rand is a recording stub returning any c_int, negatives
//! included, so the unsigned-rand slip is visible.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008F30C));

pub const classes = [_][:0]const u8{ "empty", "loop", "big-count", "wrapped-count" };

pub const stubs = struct {
    pub fn rand(ctx: *zd.Ctx) c_int {
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0: c_int = if (ctx.chance(3))
        ctx.edge(c_int, &.{ -1, -32768, -32769, -65531, -2147483648 })
    else if (ctx.chance(4))
        ctx.edge(c_int, &.{ 0, 1, 255, 256, 300 })
    else
        ctx.range(c_int, -3, 40);
    const arg1: c_int = ctx.pick(c_int, &.{ 0, 1, 255, 256, -1, 65535, 65536 });

    const n: usize = if (arg0 > 0) @intCast(arg0) else 0;
    const block = ctx.allocBytes((n + 1) * 16, 16);
    const elems: *v.D_800F1DD4_t = @ptrCast(@alignCast(block));
    v.g.D_800F1DD4().* = elems;
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    if (arg0 < -32768) return 3;
    if (arg0 <= 0) return 0;
    if (arg0 >= 256) return 2;
    return 1;
}
