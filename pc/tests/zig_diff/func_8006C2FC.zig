//! zig_diff spec: func_8006C2FC -> func_8006C2FC.func_8006C2FC (146C.c).
//! Inputs: nothing to build. The function takes no arguments and reads no
//! objects; the state (the global D_800F1968 and the scratchpad) is random.
//! The loop calls func_8009E5C4 for i = 1..15, then func_8008B4C8(0) and
//! func_80095B70(1), then stores 1 to D_800F1968. func_8009E5C4 may write
//! D_800F1968 (sometimes, with an arbitrary value), so a port that stores
//! the flag before the calls, or drops the final store, is caught by the
//! final value. The loop bound `i < 16` is compared at i == 16 on every run.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006C2FC));

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
    /// Called for i = 1..15. It may overwrite the flag the C sets last.
    pub fn func_8009E5C4(ctx: *zd.Ctx, arg0: c_int) void {
        _ = arg0;
        if (ctx.value(u1) == 1) v.g.D_800F1968().* = ctx.value(i32);
    }

    /// Returns an arbitrary int; the C ignores it.
    pub fn func_8008B4C8(ctx: *zd.Ctx, arg0: u8) c_int {
        _ = arg0;
        return ctx.value(c_int);
    }

    /// Void; may also overwrite the flag.
    pub fn func_80095B70(ctx: *zd.Ctx, arg0: c_int) void {
        _ = arg0;
        if (ctx.value(u1) == 1) v.g.D_800F1968().* = ctx.value(i32);
    }
};
