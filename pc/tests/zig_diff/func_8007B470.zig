//! zig_diff spec: func_8007B470 -> func_8007B470.func_8007B470 (146C.c).
//! The C is straight-line: no arguments and no branches of its own. The inputs
//! are the random globals and scratchpad. The callees are recording stubs. Each
//! may write D_800F1968 (the C's final store overwrites it, so a store moved
//! before a call shows), and the void stubs record their argument values for the
//! trace comparison.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B470));

pub const classes = [_][:0]const u8{"run"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}

pub const stubs = struct {
    pub fn vs_main_setClutState(ctx: *zd.Ctx, arg0: anytype) void {
        _ = arg0;
        if (ctx.value(u1) == 1) v.g.D_800F1968().* = ctx.value(i32);
    }

    pub fn func_8007B1B8(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype, d: anytype, e: anytype) void {
        _ = a;
        _ = b;
        _ = c;
        _ = d;
        _ = e;
        if (ctx.value(u1) == 1) v.g.D_800F1968().* = ctx.value(i32);
    }

    pub fn func_8006C250(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g.D_800F1968().* = ctx.value(i32);
    }

    pub fn func_8008B4BC(ctx: *zd.Ctx, arg0: anytype) void {
        _ = arg0;
        if (ctx.value(u1) == 1) v.g.D_800F1968().* = ctx.value(i32);
    }

    pub fn func_8008E480(ctx: *zd.Ctx, arg0: anytype) void {
        _ = arg0;
        if (ctx.value(u1) == 1) v.g.D_800F1968().* = ctx.value(i32);
    }
};
