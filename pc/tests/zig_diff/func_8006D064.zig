//! zig_diff spec: func_8006D064 -> func_8006D064.func_8006D064 (146C.c).
//! The C is one call and one store: it passes the global D_800F185C to
//! func_8007B29C, then sets D_800F185C to 0. Inputs: D_800F185C biased to 0,
//! negative (including INT_MIN and -1) and positive values. The callee stub
//! sometimes overwrites D_800F185C, so a port that reads it after the call,
//! or stores before the call, disagrees. The C has no branches or comparisons.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006D064));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub const stubs = struct {
    pub fn func_8007B29C(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype, d: anytype, e: anytype, f: anytype) void {
        _ = .{ a, b, c, d, e, f };
        // The real callee may change the global the C passed it.
        if (ctx.value(u1) == 1) v.g.D_800F185C().* = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = v.g.D_800F185C();
    d.* = ctx.pick(i32, &.{ 0, -1, std.math.minInt(i32), std.math.maxInt(i32) });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F185C().*;
    if (d == 0) return 0;
    if (d < 0) return 1;
    return 2;
}
