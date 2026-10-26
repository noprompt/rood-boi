//! zig_diff spec: func_80077F14 -> func_80077F14.func_80077F14 (146C.c).
//! Inputs: arg1 is -1 about a third of the time (the C's only test, which
//! selects 0 instead of the func_800A152C result) and otherwise an edge or
//! random value (-2, 0, 1, 2, the int extremes). arg0 is an edge or random
//! int. arg2 is null about one time in five (the C never dereferences it,
//! so null must pass through) and otherwise a fresh arena SVECTOR. The
//! callees are recording stubs: func_800A152C returns any int, and
//! func_800A1AF8 may rewrite the SVECTOR it is passed.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80077F14));

pub const classes = [_][:0]const u8{ "minus-one", "other-null-arg2", "other-arg2" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0: c_int = ctx.pick(c_int, &.{ 0, 1, -1, 0x7fffffff, -0x80000000 });
    const arg1: c_int = if (ctx.chance(3))
        -1
    else
        ctx.pick(c_int, &.{ 0, 1, -2, 2, 0x7fffffff, -0x80000000 });
    const sv: ?*v.SVECTOR = if (ctx.chance(5)) null else ctx.alloc(v.SVECTOR);
    return .{ arg0, arg1, sv };
}

pub fn classify(args: Args) usize {
    if (args[1] == -1) return 0;
    if (args[2] == null) return 1;
    return 2;
}

pub const stubs = struct {
    pub fn func_800A152C(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) c_int {
        _ = a;
        _ = b;
        _ = c;
        return ctx.value(c_int);
    }

    pub fn func_800A1AF8(ctx: *zd.Ctx, a: anytype, b: anytype, p: anytype, d: anytype) void {
        _ = a;
        _ = b;
        _ = d;
        // The callee may rewrite the SVECTOR it is given (never when null).
        const raw: ?*anyopaque = @ptrCast(p);
        const sv: *v.SVECTOR = @ptrCast(@alignCast(raw orelse return));
        if (ctx.value(u1) == 1) sv.vx = ctx.value(i16);
        if (ctx.value(u1) == 1) sv.vy = ctx.value(i16);
        if (ctx.value(u1) == 1) sv.vz = ctx.value(i16);
    }
};
