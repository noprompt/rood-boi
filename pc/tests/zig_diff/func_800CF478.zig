//! zig_diff spec: func_800CF478 -> func_800CF478.func_800CF478 (5BF94.c).
//! The unit's whole body stores its argument into the global D_800F531C (a u32).
//! Inputs: an int argument that is zero, negative, or positive, drawn from edge
//! values (0, 1, -1, INT_MAX, INT_MIN, 0xFFFF, 0x8000) half the time and any
//! int otherwise, so the sign bit, the high half-word and the zero case are all
//! seen. The global starts as random bytes in both runs, so a store that is
//! dropped or narrowed shows in the compared state.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF478));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg: c_int = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000, 0xFFFF, 0x8000 });
    return .{arg};
}

pub fn classify(args: Args) usize {
    if (args[0] < 0) return 1;
    if (args[0] == 0) return 0;
    return 2;
}
