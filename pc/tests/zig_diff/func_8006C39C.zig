//! zig_diff spec: func_8006C39C -> func_8006C39C.func_8006C39C (146C.c).
//! The C body is straight-line: eight calls in a fixed order, then
//! D_800F1968 = 1. There are no branches or comparisons, so the coverage is
//! the call sequence and the final store. The inputs vary only the global
//! D_800F1968 (prepare sets it to 0, 1 or -1), so the two classes differ in
//! its prior value. The callees return ints the C ignores and change no state
//! the C reads back, so their stubs draw the default values. The trace
//! (arguments, and a hash of the state at each call) checks the order and
//! arguments of the calls.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");
const port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_8006C39C));

pub const classes = [_][:0]const u8{ "flag-was-one", "flag-was-other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    // The C never reads D_800F1968 before storing it, but the port must
    // overwrite it whatever it held.
    v.g.D_800F1968().* = ctx.pick(i32, &.{ 0, 1, -1 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F1968().* == 1) 0 else 1;
}
