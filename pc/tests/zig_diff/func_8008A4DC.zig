//! zig_diff spec: func_8008A4DC -> func_8008A4DC.func_8008A4DC (146C.c).
//! Inputs: arg0 zero (the else store), one, -1 and the sign-bit, maximum and
//! wide values (the nonzero store, with and without the sign bit), plus
//! random ints. The global D_800F190C starts random so a missed store shows.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008A4DC));

pub const classes = [_][:0]const u8{ "zero", "nonzero" };

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F190C().* = ctx.int(i32);
    const arg: c_int = ctx.pick(c_int, &.{
        0,
        1,
        -1,
        2,
        std.math.minInt(c_int),
        std.math.maxInt(c_int),
        256,
        0x10000,
    });
    return .{arg};
}

pub fn classify(args: Args) usize {
    return if (args[0] == 0) 0 else 1;
}
