//! zig_diff spec: func_8007C36C -> func_8007C36C.func_8007C36C (146C.c).
//! Inputs: the tick speed selector arg0 as 2 and 4 (each takes one arm of the
//! `||`), and every other value (0, 1, 3, negatives, the c_int extremes). The
//! global vs_gametime_tickspeed starts as random bytes and is sometimes set to
//! an edge value first, so the returned value is checked both when the store
//! happens and when it does not.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C36C));

pub const classes = [_][:0]const u8{ "two", "four", "other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const speed = v.g.vs_gametime_tickspeed();
    if (ctx.chance(4)) speed.* = ctx.pick(i32, &.{ 0, 2, 4, -1 });
    const arg0: c_int = ctx.pick(c_int, &.{ 2, 4, 0, 1, 3, -1, -2, -4, 0x7FFFFFFF, -2147483648 });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    return switch (args[0]) {
        2 => 0,
        4 => 1,
        else => 2,
    };
}
