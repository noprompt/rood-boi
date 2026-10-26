//! zig_diff spec: func_8008D594 -> func_8008D594.func_8008D594 (146C.c).
//! The C is a single store: `D_800F1D6E = arg0;`, truncating an int to the
//! i8 global. Inputs: arg0 from edge values (0, +-1, the i8 and i16 limits,
//! 255/256 and the int extremes) and random ints, so the low byte, the bits
//! above it and the sign are all varied. The global's prior value is random
//! from the state fill and must be overwritten.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008D594));

pub const classes = [_][:0]const u8{ "zero", "fits-i8", "wider-than-i8" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 127, 128, -128, -129, 255, 256, 0x7FFF, -0x8000, 0x7FFF_FFFF, -0x7FFF_FFFF - 1 });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const x = args[0];
    if (x == 0) return 0;
    if (x >= -128 and x <= 127) return 1;
    return 2;
}
