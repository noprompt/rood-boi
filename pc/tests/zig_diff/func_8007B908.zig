//! zig_diff spec: func_8007B908 -> func_8007B908.func_8007B908 (146C.c).
//! Inputs: D_800F1868 (an i32 the C tests as `D_800F1868 & 3`) drawn from
//! edges that cover low bits zero and nonzero, with and without the sign bit,
//! plus random bytes from the harness fill. The callee func_8007B63C is a
//! recording stub that sometimes rewrites D_800F1868, as a real callee may.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B908));

pub const classes = [_][:0]const u8{
    "low-bits-zero-nonneg",
    "low-bits-zero-neg",
    "low-bits-nonzero-nonneg",
    "low-bits-nonzero-neg",
};

pub const stubs = struct {
    pub fn func_8007B63C(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g.D_800F1868().* = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F1868().* = ctx.pick(i32, &.{
        0,
        1,
        2,
        3,
        4,
        -1,
        -2,
        -3,
        -4,
        0x40000000,
        0x7FFFFFFC,
        std.math.minInt(i32),
        std.math.minInt(i32) + 1,
    });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.D_800F1868().*;
    const low_zero = (x & 3) == 0;
    const neg = x < 0;
    const base: usize = if (low_zero) 0 else 2;
    return base + @as(usize, if (neg) 1 else 0);
}
