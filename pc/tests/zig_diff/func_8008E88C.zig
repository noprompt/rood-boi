//! zig_diff spec: func_8008E88C -> func_8008E88C.func_8008E88C (146C.c).
//! Inputs: the unit has no branches of its own. It stores constants into
//! nine globals and then calls func_8008E938. The globals start as random
//! bytes, so every store is visible in the state comparison. The callee's
//! stub writes two globals with `ctx.value`, as the real callee may, so a
//! port that reads them back after the call is caught. The call trace hashes
//! the state at the call, so a store moved across the call is also caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E88C));

pub const classes = [_][:0]const u8{"run"};

pub const stubs = struct {
    pub fn func_8008E938(ctx: *zd.Ctx) void {
        // The callee may change these globals; the C does not read them back.
        v.g.D_800F1DBC().* = ctx.value(i16);
        v.g.D_800F1DCB().* = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
