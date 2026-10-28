//! zig_diff spec: func_80073554 -> func_80073554.func_80073554 (146C.c).
//! The C has no branches: it sets D_800F196C to 1 and calls func_8006C40C.
//! Inputs: D_800F196C starts as random bytes, and in some runs already holds 1
//! (the store then changes nothing). The callee's stub sometimes rewrites
//! D_800F196C with a value of its own, so a port that stores after the call,
//! or never stores, is seen through the global and through the call's state hash.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80073554));

pub const classes = [_][:0]const u8{ "flag-already-set", "flag-other" };

pub const stubs = struct {
    pub fn func_8006C40C(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g.D_800F196C().* = ctx.value(u32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(2)) v.g.D_800F196C().* = 1;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F196C().* == 1) 0 else 1;
}
