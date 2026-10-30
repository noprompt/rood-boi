//! zig_diff spec: func_8007C050 -> func_8007C050.func_8007C050 (146C.c).
//! Inputs: none. The function takes no arguments and its only effect is the
//! loop i = 0..15 calling func_8007BFF8(i), so every run takes the same
//! path. The trace compares each call's argument and the state hash at the
//! call, which catches a wrong start, bound, step or argument. The callee is
//! a recording stub that may write one arena byte, chosen by ctx.value, so a
//! port that reads that byte around the call is caught too.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C050));

pub const classes = [_][:0]const u8{"all"};

pub const stubs = struct {
    /// The real callee may change memory; model it by writing one arena
    /// byte on some calls, with a value drawn the same way in both runs.
    pub fn func_8007BFF8(ctx: *zd.Ctx, i: c_int) void {
        _ = i;
        if (ctx.value(u1) == 1) zd.zdiff_arena[0] = ctx.value(u8);
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
