//! zig_diff spec: func_8008EAF8 -> func_8008EAF8.func_8008EAF8 (146C.c).
//! The C is one store: D_800F1DC9 = arg0, a u8 global taking the low byte of
//! an int. Inputs: arg0 drawn from the values that matter to that narrowing
//! (0, 1, -1, 255, 256, the int extremes) plus any random int, so both
//! signs, the high bits and the low byte's wrap are all compared. The global
//! starts as random bytes from the harness, so a dropped store shows.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008EAF8));

pub const classes = [_][:0]const u8{ "negative", "nonnegative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 255, 256, 0x7FFF_FFFF, -0x8000_0000 });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    return if (args[0] < 0) 0 else 1;
}
