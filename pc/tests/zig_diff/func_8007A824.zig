//! zig_diff spec: func_8007A824 -> func_8007A824.func_8007A824 (146C.c).
//! Inputs: an out-pointer that is either null (the C passes it through
//! untested) or points at an arena int, and the global D_800F1870 pointing at
//! an arena block large enough for the 0x2084 offset. The callee stub writes
//! a value into the out-parameter when it is non-null, so the C's result
//! must agree with the port's on every path.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007A824));

pub const classes = [_][:0]const u8{ "out-null", "out-valid" };

pub const stubs = struct {
    pub fn func_800C64D0(ctx: *zd.Ctx, a: anytype, out: anytype) void {
        _ = a;
        if (out == null) return;
        out[0] = ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const base = ctx.allocBytes(0x2100, 16);
    const p: *anyopaque = @ptrCast(base);
    v.g.D_800F1870().* = p;
    const out: [*c]c_int = if (ctx.chance(4)) null else @ptrCast(@alignCast(ctx.alloc(c_int)));
    return .{out};
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}
