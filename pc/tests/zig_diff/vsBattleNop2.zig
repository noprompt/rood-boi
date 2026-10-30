//! zig_diff spec: _vsBattleNop2 -> vs_battle_nop2.vsBattleNop2 (146C.c).
//! The C body is empty and makes no calls, so the only input is arg0: zero,
//! -1, the int extremes and random values, covering both sign-bit states.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").vsBattleNop2));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.pick(c_int, &.{ 0, 1, -1, std.math.maxInt(c_int), std.math.minInt(c_int) })};
}

pub fn classify(args: Args) usize {
    if (args[0] == 0) return 0;
    return if (args[0] < 0) 1 else 2;
}
