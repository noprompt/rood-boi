//! zig_diff spec: func_8007E180 -> func_8007E180.func_8007E180 (146C.c).
//! Inputs: the argument over edges (0, 1, -1, 0x80, 0x100 whose low byte is
//! zero, and the int extremes), and the global D_800F18F8 either zero or one
//! of several nonzero bytes (including the sign bit), so both branches run.
//! The void call's stub may rewrite the global; the C never reads it back,
//! and the call trace hashes the state, so a port that reorders the store
//! around the call is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007E180));

pub const classes = [_][:0]const u8{ "global-zero", "global-nonzero" };

pub const stubs = struct {
    pub fn vs_main_nop9(ctx: *zd.Ctx, a: c_int, b: c_int) void {
        _ = a;
        _ = b;
        if (ctx.value(u1) == 1) v.g.D_800F18F8().* = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const g = v.g.D_800F18F8();
    if (ctx.chance(2)) {
        g.* = 0;
    } else {
        g.* = ctx.pick(u8, &.{ 1, 0x7F, 0x80, 0xFF });
    }
    const arg = ctx.pick(c_int, &.{ 0, 1, -1, 0x80, 0x100, std.math.minInt(c_int), std.math.maxInt(c_int) });
    return .{arg};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F18F8().* == 0) 0 else 1;
}
