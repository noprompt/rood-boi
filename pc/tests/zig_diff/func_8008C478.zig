//! zig_diff spec: func_8008C478 -> func_8008C478.func_8008C478 (146C.c).
//! Inputs: vs_battle_roomData.section7 is zero (1 in 4), negative, or positive
//! (edges and random i32s, so the sign bit is set and clear), and arg0 is an
//! edge value or a random i32, including values where arg0 * 8 wraps. The
//! function makes no calls: its only state is the room's section7 field.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008C478));

pub const classes = [_][:0]const u8{ "section7-zero", "section7-negative", "section7-positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    if (ctx.chance(4)) {
        room.section7 = 0;
    } else {
        room.section7 = ctx.pick(i32, &.{ 1, -1, 0x40, std.math.maxInt(i32), std.math.minInt(i32) });
    }
    const arg0 = ctx.pick(c_int, &.{
        0,
        1,
        -1,
        0x1FFF_FFFF,
        0x2000_0000,
        std.math.minInt(c_int),
        std.math.maxInt(c_int),
    });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    _ = args;
    const s = v.g.vs_battle_roomData().section7;
    if (s == 0) return 0;
    if (s < 0) return 1;
    return 2;
}
