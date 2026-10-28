//! zig_diff spec: func_8007D340 -> func_8007D340.func_8007D340 (146C.c).
//! The C is a single call, `_removeActorAtIndex(arg0, 0)`, with its result
//! discarded. The inputs are the index `arg0` over the values a porter could
//! mishandle: 0, the small indices around 31, 32, 255 and 256 where an
//! unsigned narrowing would show, -1 and INT_MIN (the sign reinterpreted as
//! u_int), INT_MAX, and 0xFFFF. The callee is an extern stub with no state
//! reached through this unit's views, so it records its arguments and returns
//! `ctx.value`; the C never reads anything back from it.

const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007D340));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &.{
        0, 1, -1, 2, 31, 32, 255, 256, 257, 0xFFFF,
        0x7FFF_FFFF, -0x8000_0000,
    });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const a = args[0];
    if (a == 0) return 0;
    return if (a < 0) 1 else 2;
}
