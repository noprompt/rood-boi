//! zig_diff spec: func_800D1DE4 -> func_800D1DE4.func_800D1DE4 (5BF94.c).
//! Inputs: an arg0 that is zero, has bit 7 set, or is another value; the
//! edges include 0, -1, 0x7F, 0x80, 0xFF, 0x100 and the int extremes, plus
//! random ints. The global D_800F5518 keeps its random byte, so the OR
//! merges with old bits, and the mutations (and, xor, plain store, masked
//! and shifted operands) change that byte.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D1DE4));

pub const classes = [_][:0]const u8{ "zero", "bit7-set", "other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7F, 0x80, 0xFF, 0x100, std.math.minInt(c_int), std.math.maxInt(c_int) });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    if (arg0 == 0) return 0;
    if ((@as(u32, @bitCast(arg0)) & 0x80) != 0) return 1;
    return 2;
}
