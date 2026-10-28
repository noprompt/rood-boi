//! zig_diff spec: func_8007DE44 -> func_8007DE44.func_8007DE44 (146C.c).
//! Inputs: one c_uint argument, drawn from edges around the 0x800 bound
//! (0, 0x7FF, 0x800, 0x801) and the high-bit values (0x80000000, 0xFFFFFFFF)
//! that a signed compare would misread, plus any random value. The global
//! D_800F1A44 starts as random bytes, so a store that is skipped or made to
//! the wrong value shows in the state comparison.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DE44));

pub const classes = [_][:0]const u8{ "below", "equal", "above" };

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.pick(c_uint, &.{ 0, 0x7FF, 0x800, 0x801, 0x80000000, 0xFFFFFFFF })};
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    if (arg0 < 0x800) return 0;
    if (arg0 == 0x800) return 1;
    return 2;
}
