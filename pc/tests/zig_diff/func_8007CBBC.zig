//! zig_diff spec: func_8007CBBC -> func_8007CBBC.func_8007CBBC (146C.c).
//! The C is one call: func_8009CC20(arg0, 1), its int result discarded. The
//! inputs cover arg0 at 0, 1, -1 and the int extremes, plus random values, so
//! the forwarded argument is checked across its sign and width. The callee is
//! a recording stub that returns a value the C ignores, and that also writes
//! the scratchpad the way a real callee's side effect would, so the port must
//! make the call at the same point with the same state.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CBBC));

pub const classes = [_][:0]const u8{ "arg-zero", "arg-negative", "arg-positive" };

pub const stubs = struct {
    pub fn func_8009CC20(ctx: *zd.Ctx, a: anytype, b: anytype) c_int {
        _ = a;
        _ = b;
        // A side effect the C never reads back: the callee's scratchpad write.
        const p: *align(1) u32 = @ptrFromInt(zd.scratchpad + 0x40);
        p.* = ctx.value(u32);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 2, 255, 256, std.math.maxInt(c_int), std.math.minInt(c_int) });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const a = args[0];
    if (a == 0) return 0;
    if (a < 0) return 1;
    return 2;
}
