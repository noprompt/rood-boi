//! zig_diff spec: func_8006CDB8 -> func_8006CDB8.func_8006CDB8 (146C.c).
//! The C is a single forwarding call, `func_8009D854(arg0)`, with no branch,
//! no comparison and no memory access of its own. The inputs are the int
//! argument, drawn from edges (0, 1, -1, INT_MAX, INT_MIN, 256) and random
//! values, so the sign, zero and wrap cases all reach the call. The callee is
//! external and the C reads nothing back from it, so its stub only records the
//! call (it writes no state and returns void).
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006CDB8));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub const stubs = struct {
    /// Void callee: the C reads nothing it could change, so nothing is written back.
    pub fn func_8009D854(ctx: *zd.Ctx, a: c_int) void {
        _ = ctx;
        _ = a;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg: c_int = if (ctx.chance(4))
        ctx.pick(c_int, &.{ 0, 1, -1, std.math.maxInt(c_int), std.math.minInt(c_int), 256 })
    else
        ctx.int(c_int);
    return .{arg};
}

pub fn classify(args: Args) usize {
    const a = args[0];
    if (a < 0) return 0;
    if (a == 0) return 1;
    return 2;
}
