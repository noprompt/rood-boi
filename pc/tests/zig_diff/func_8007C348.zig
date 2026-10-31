//! zig_diff spec: func_8007C348 -> func_8007C348.func_8007C348 (146C.c).
//! Inputs: two c_int arguments drawn from edge values (0, 1, -1, the 16-bit
//! and 32-bit extremes) or random bits; in a quarter of the runs arg1 equals
//! arg0. The body has no branch: what is compared is the call to
//! func_8009F314 (arg0, a NULL pointer, arg1) and the return.
const std = @import("std");
const zd = @import("zdiff");
const port = @import("port");
pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_8007C348));

pub const classes = [_][:0]const u8{ "equal-args", "distinct-args" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const edges = [_]c_int{ 0, 1, -1, 0x7fff, 0x8000, -0x8000, 0x7fffffff, -0x7fffffff - 1 };
    const a0 = ctx.pick(c_int, &edges);
    const a1 = if (ctx.chance(4)) a0 else ctx.pick(c_int, &edges);
    return .{ a0, a1 };
}

pub fn classify(args: Args) usize {
    return if (args[0] == args[1]) 0 else 1;
}
