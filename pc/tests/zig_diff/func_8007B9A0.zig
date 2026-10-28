//! zig_diff spec: func_8007B9A0 -> func_8007B9A0.func_8007B9A0 (146C.c).
//! The C has no arguments and no branches: it zeroes two i32 globals
//! (D_800F1860, D_800F1864) and calls func_8007B7DC. The inputs are the
//! random globals and the arena (which the callee stub does not use). The
//! callee stub overwrites the two globals with ctx.value draws, some calls
//! only one of them, so the state the next run starts from differs between
//! the two stores and the call. Mutations catch a dropped store, a wrong
//! constant, a wrong target, a store moved across the call, and a dropped call.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
const port = @import("port");
pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_8007B9A0));

pub const classes = [_][:0]const u8{"reset"};

pub const stubs = struct {
    pub fn func_8007B7DC(ctx: *zd.Ctx) void {
        // The real callee may change either global; the C never reads them back.
        if (ctx.value(u1) == 1) v.g.D_800F1860().* = ctx.value(i32);
        v.g.D_800F1864().* = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // Only the globals (random bytes from the harness) matter; no arguments.
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
