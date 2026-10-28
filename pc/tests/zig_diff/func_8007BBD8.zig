//! zig_diff spec: func_8007BBD8 -> func_8007BBD8.func_8007BBD8 (146C.c).
//! Inputs: arg0 is 1 about a third of the time (the only branch test) and
//! otherwise an edge value (0, -1, the minimum, 256 and so on); arg1 is any
//! int; arg2 covers the byte boundaries of its four fields (0, 255, 256,
//! 65535, 65536, 16777215, 16777216) and negative values, where C's `/` and
//! `%` truncate toward zero. Stubs rewrite D_80050468 fields in some calls,
//! so a port that caches the fields across a call fails.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BBD8));

pub const classes = [_][:0]const u8{ "arg0-is-1", "arg0-other-negative-arg2", "arg0-other-nonnegative-arg2" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0: c_int = if (ctx.chance(3)) 1 else ctx.pick(c_int, &.{ 0, 2, -1, 256, 257, 65536, std.math.minInt(c_int) });
    const arg1: c_int = ctx.int(c_int);
    const arg2: c_int = ctx.pick(c_int, &.{
        0,      1,        255,       256,      257,         65535,        65536,
        16777215, 16777216, -1,      -256,     std.math.minInt(c_int), std.math.maxInt(c_int),
    });
    return .{ arg0, arg1, arg2 };
}

pub fn classify(args: Args) usize {
    if (args[0] == 1) return 0;
    if (args[2] < 0) return 1;
    return 2;
}

pub const stubs = struct {
    pub fn vs_battle_setStateFlag(ctx: *zd.Ctx, id: anytype, value: anytype) void {
        _ = value;
        const g = v.g.D_80050468();
        // The callee may rewrite the block the C reads back for the next flag.
        if (id == 0xA1 and ctx.value(u1) == 1) g.minutes = ctx.value(i8);
        if (ctx.value(u3) == 0) g.unk2 = ctx.value(u16);
    }

    pub fn func_800CB550(ctx: *zd.Ctx) void {
        if (ctx.value(u2) == 0) v.g.D_80050468().unk0 = ctx.value(u8);
    }
};
