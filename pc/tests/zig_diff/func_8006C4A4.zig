//! zig_diff spec: func_8006C4A4 -> func_8006C4A4.func_8006C4A4 (146C.c).
//! The C is a single call, `func_800CF830(arg0, arg1)`, with no branch and no
//! read after the call, so the inputs are the two arguments alone: each drawn
//! from the edges 0, -1, INT_MIN and INT_MAX half the time and random bits
//! otherwise. Classes split on arg0's sign and zero, so the sign bit and zero
//! both occur. The callee is void and the C reads nothing back from it, so
//! its stub is the default recording stub with no state to model.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006C4A4));

pub const classes = [_][:0]const u8{ "arg0-zero", "arg0-negative", "arg0-positive" };

const edges = [_]c_int{ 0, -1, std.math.minInt(c_int), std.math.maxInt(c_int) };

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ ctx.pick(c_int, &edges), ctx.pick(c_int, &edges) };
}

pub fn classify(args: Args) usize {
    if (args[0] == 0) return 0;
    return if (args[0] < 0) 1 else 2;
}
