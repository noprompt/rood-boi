//! zig_diff spec: func_8006CD60 -> func_8006CD60.func_8006CD60 (146C.c).
//! Inputs: arg0 is null or an arena word (the C only passes it on, so the
//! callee's write through it is modelled), arg1 and arg2 are edge values
//! and random ints. vs_main_getRand returns negative values (the sign-bit
//! case of `+ 8` and the u_int conversion) and values up to 2^30, which
//! keep `+ 8` clear of signed overflow (the C would be undefined there).
//! The C has no branches; the spec exercises the call's arguments, the
//! getRand draw and the callee's write.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006CD60));

pub const classes = [_][:0]const u8{ "null-arg0", "arena-arg0" };

pub const stubs = struct {
    /// The C's getRand result: negative values half the time, otherwise up to 2^30.
    pub fn vs_main_getRand(ctx: *zd.Ctx, n: anytype) c_int {
        _ = n;
        if (ctx.value(u8) < 128) return @as(c_int, ctx.value(i16));
        return @intCast(ctx.value(u30));
    }

    /// The callee may write the buffer it is given (arg0 when non-null).
    pub fn func_800461CC(ctx: *zd.Ctx, a: anytype, p: anytype, b: anytype, d: anytype, e: anytype) void {
        _ = a;
        _ = b;
        _ = d;
        _ = e;
        if (p != null) p[0] = ctx.value(c_uint);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    var p: [*c]c_uint = null;
    if (!ctx.chance(5)) p = ctx.alloc(c_uint);
    const edges = [_]c_int{ 0, 1, -1, 7, 0x7FFF_FFF0, -0x7FFF_FFFF, -0x8000_0000 };
    return .{ p, ctx.pick(c_int, &edges), ctx.pick(c_int, &edges) };
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}
