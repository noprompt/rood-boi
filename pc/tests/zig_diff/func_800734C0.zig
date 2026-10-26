//! zig_diff spec: func_800734C0 -> func_800734C0.func_800734C0 (146C.c).
//! Inputs: none, since the function takes no arguments; the state is random
//! bytes. The C calls func_8009E5C4(i) for i in 0..15, then
//! func_8007C0AC(0, 2), then stores 10 to D_800F196C. Both callees are
//! stubs that may rewrite D_800F196C, the global the C stores last, so a port
//! that moves the store across a call is caught by the call-state hashes, and
//! a port that drops or changes the store is caught by the final state.
//! The classes split on whether D_800F196C already holds 10 when the C runs
//! (prepare sets it so one time in three), so both the store-is-a-no-op and
//! the store-changes-the-global cases occur.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800734C0));

pub const classes = [_][:0]const u8{ "already-10", "other-value" };

pub const stubs = struct {
    pub fn func_8009E5C4(ctx: *zd.Ctx, i: anytype) void {
        _ = i;
        if (ctx.value(bool)) v.g.D_800F196C().* = ctx.value(u32);
    }

    pub fn func_8007C0AC(ctx: *zd.Ctx, a: anytype, b: anytype) void {
        _ = a;
        _ = b;
        if (ctx.value(bool)) v.g.D_800F196C().* = ctx.value(u32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(3)) v.g.D_800F196C().* = 10;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F196C().* == 10) 0 else 1;
}
