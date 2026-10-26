//! zig_diff spec: func_8006D028 -> func_8006D028.func_8006D028 (146C.c).
//! Inputs: the one int argument, drawn from zero, negative and positive
//! edges (both sign bits, the extremes). The C stores it into D_800F185C and
//! calls func_8007B29C with fixed arguments and the argument in the third
//! slot. The callee stub is a recording stub that sometimes overwrites
//! D_800F185C, as the real callee may, so a port that reorders the store
//! across the call, or reads the global back, is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
const c = @import("c_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006D028));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub const stubs = struct {
    pub fn func_8007B29C(ctx: *zd.Ctx, a: anytype, b: anytype, cc: anytype, d: anytype, e: anytype, f: anytype) void {
        _ = a;
        _ = b;
        _ = cc;
        _ = d;
        _ = e;
        _ = f;
        // The real callee may change the global the C just stored.
        if (ctx.value(u1) == 1) v.g.D_800F185C().* = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000, 0x10, 0xE });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    if (arg0 == 0) return 0;
    if (arg0 < 0) return 1;
    return 2;
}
