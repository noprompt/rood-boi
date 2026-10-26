//! zig_diff spec: func_8007CEA0 -> func_8007CEA0.func_8007CEA0 (146C.c).
//! The C is one call: `func_8009E5C4(arg0)`, with no branch of its own. The
//! inputs cover the argument's edges (0, 1, -1, the 16-bit boundaries, the
//! int extremes and random values), so a port that narrows, flips, drops or
//! doubles the call shows in the call trace. Classes split by the argument's
//! sign and zero. The callee is a recording stub that may overwrite a
//! scratchpad word, the one state it can change that the C never reads back.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CEA0));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub const stubs = struct {
    pub fn func_8009E5C4(ctx: *zd.Ctx, a: c_int) void {
        _ = a;
        // The callee may write the scratchpad: a value both runs draw alike.
        const sp: *u32 = @ptrFromInt(zd.scratchpad);
        if (ctx.value(u1) == 1) sp.* = ctx.value(u32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF, -0x8000, 0x8000, 0xFFFF, 0x10000, std.math.minInt(c_int), std.math.maxInt(c_int) })};
}

pub fn classify(args: Args) usize {
    const x = args[0];
    if (x == 0) return 0;
    if (x < 0) return 1;
    return 2;
}
