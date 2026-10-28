//! zig_diff spec: func_8007820C -> func_8007820C.func_8007820C (146C.c).
//! Inputs: arg0 as the C's int takes it: 0, 1, -1 (the sign bit set), 2, and
//! the int extremes, so the `!= 0` test sees nonzero values with and without
//! the sign bit. The C's one callee writes the SVECTOR it is passed (the
//! stub fills it with ctx.value), and the second callee writes it sometimes
//! and returns a value the C ignores. Both recording stubs make the call
//! trace, so a dropped, reordered or re-argued call is a mismatch.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007820C));

pub const classes = [_][:0]const u8{ "zero", "one", "negative", "other-positive" };

pub const stubs = struct {
    pub fn func_800780A8(ctx: *zd.Ctx, p: anytype) void {
        const s: *v.SVECTOR = @ptrCast(@alignCast(p));
        s.vx = ctx.value(i16);
        s.vy = ctx.value(i16);
        s.vz = ctx.value(i16);
    }

    pub fn _stepTowardTarget(ctx: *zd.Ctx, p: anytype, a: anytype, b: anytype) c_int {
        _ = a;
        _ = b;
        const s: *v.SVECTOR = @ptrCast(@alignCast(p));
        if (ctx.value(bool)) s.vx = ctx.value(i16);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.pick(c_int, &.{ 0, 1, -1, 2, std.math.minInt(c_int), std.math.maxInt(c_int) })};
}

pub fn classify(args: Args) usize {
    const a = args[0];
    if (a == 0) return 0;
    if (a == 1) return 1;
    if (a < 0) return 2;
    return 3;
}
