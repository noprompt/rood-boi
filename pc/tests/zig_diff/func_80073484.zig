//! zig_diff spec: func_80073484 -> func_80073484.func_80073484 (146C.c).
//! The C has no arguments and no branches: it calls func_8006F5CC, stores 2
//! into vs_gametime_tickspeed, then calls func_800CB654(0) and func_8008B4C8(1).
//! The random scratchpad and arena give random initial values for the global, so
//! a dropped, moved or wrong store is visible in the state hash at the next call.
//! prepare biases the starting tickspeed toward 2 and the other edge values, so
//! both input classes occur. The callees may write vs_gametime_tickspeed, and
//! func_8008B4C8 returns any c_int (the C discards it). Stubs draw only ctx.value.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80073484));

pub const classes = [_][:0]const u8{ "start-2", "start-other" };

pub const stubs = struct {
    pub fn func_8006F5CC(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g.vs_gametime_tickspeed().* = ctx.value(i32);
    }

    pub fn func_800CB654(ctx: *zd.Ctx, arg0: anytype) void {
        _ = arg0;
        if (ctx.value(u1) == 1) v.g.vs_gametime_tickspeed().* = ctx.value(i32);
    }

    pub fn func_8008B4C8(ctx: *zd.Ctx, arg0: anytype) c_int {
        _ = arg0;
        if (ctx.value(u1) == 1) v.g.vs_gametime_tickspeed().* = ctx.value(i32);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.vs_gametime_tickspeed().* = ctx.pick(i32, &.{ 0, 1, 2, -1, 3 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.vs_gametime_tickspeed().* == 2) 0 else 1;
}
