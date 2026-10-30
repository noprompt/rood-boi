//! zig_diff spec: func_8007B7DC -> func_8007B7DC.func_8007B7DC (146C.c).
//! Inputs: the state flag the stub returns, chosen in prepare from edges that
//! include 3 (so `>=` sees its sides equal about one run in ten), values
//! below 3 (the false branch), and values above 3. The three callees are
//! recording stubs that may overwrite _cameraMode, which the C stores to
//! before func_8007B410 and never reads back, so the store order shows in
//! the state hashed at each call.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B7DC));

pub const classes = [_][:0]const u8{ "flag-below-3", "flag-equal-3", "flag-above-3" };

/// The flag vs_battle_getStateFlag returns this iteration (set by prepare).
var want_flag: u8 = 0;

pub const stubs = struct {
    pub fn vs_battle_getStateFlag(ctx: *zd.Ctx, id: anytype) u8 {
        _ = ctx;
        _ = id;
        return want_flag;
    }
    pub fn func_800CB23C(ctx: *zd.Ctx) void {
        v.g._cameraMode().* = ctx.value(u32);
    }
    pub fn func_8007B410(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g._cameraMode().* = ctx.value(u32);
    }
    pub fn func_8007B764(ctx: *zd.Ctx) void {
        v.g._cameraMode().* = ctx.value(u32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    want_flag = ctx.pick(u8, &.{ 0, 2, 3, 4, 255 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (want_flag < 3) return 0;
    if (want_flag == 3) return 1;
    return 2;
}
