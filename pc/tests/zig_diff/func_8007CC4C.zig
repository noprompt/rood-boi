//! zig_diff spec: func_8007CC4C -> func_8007CC4C.func_8007CC4C (146C.c).
//! The C is a single call that forwards its argument to func_8009D208, so the
//! inputs are the argument alone: edge values (0, -1, the int extremes) and
//! random bits, so that narrowing, masking and off-by-one slips all change the
//! argument the callee records. The callee is a recording stub (the C reads
//! nothing back from it and discards its result), so the default void stub is
//! used.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CC4C));

pub const classes = [_][:0]const u8{ "negative", "nonnegative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000, 0xFFFF, 0x1_0000 })};
}

pub fn classify(args: Args) usize {
    return if (args[0] < 0) 0 else 1;
}
