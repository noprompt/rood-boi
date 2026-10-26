//! zig_diff spec: func_8008B4C8 -> func_8008B4C8.func_8008B4C8 (146C.c).
//! Inputs: the one byte argument, from the edges 0, 1, 0x7F, 0x80, 0xFF
//! (half the time) and any byte otherwise. The global D_800F1CD6 keeps the
//! harness's random fill, so the old value differs from the new one. The C
//! has no branches and no calls; the checks are that the store reaches the
//! global and that the return is the stored value, not the argument or the
//! old value.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B4C8));

pub const classes = [_][:0]const u8{ "zero", "sign-bit", "low-bits" };

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.pick(u8, &.{ 0, 1, 0x7F, 0x80, 0xFF })};
}

pub fn classify(args: Args) usize {
    const x = args[0];
    if (x == 0) return 0;
    if ((x & 0x80) != 0) return 1;
    return 2;
}
