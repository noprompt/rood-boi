//! zig_diff spec: func_8008ABB8 -> func_8008ABB8.func_8008ABB8 (146C.c).
//! Inputs: vs_battle_roomData.unk0 is 1 about half the time and otherwise one
//! of 0, 2, 0x81, 255 (the `== 1` test against nonzero and sign-bit values).
//! unk2 is an i16 from 0, 1, -1, 32767, -32768. arg0 equals unk2 (widened)
//! about half the time, equals unk2's low 16 bits (so a negative unk2 meets
//! a positive arg0 such as 65535) about a third of the remaining time, and
//! otherwise takes edge values (65536, -65536, INT_MIN, INT_MAX). The C has no
//! callees and no ordered comparisons; the state it writes is unk1.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008ABB8));

pub const classes = [_][:0]const u8{ "room-not-1", "room-1-arg-differs", "match" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    room.unk0 = ctx.pick(u8, &.{ 0, 1, 2, 0x81, 255 });
    if (ctx.chance(2)) room.unk0 = 1;
    room.unk2 = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    const arg: c_int = if (ctx.chance(2))
        @as(c_int, room.unk2)
    else if (ctx.chance(3))
        @as(c_int, @as(u16, @bitCast(room.unk2)))
    else
        ctx.pick(c_int, &.{ 0, 1, -1, 65535, 65536, -65536, 0x7FFF_FFFF, -0x8000_0000 });
    return .{arg};
}

pub fn classify(args: Args) usize {
    const room = v.g.vs_battle_roomData();
    if (room.unk0 != 1) return 0;
    if (@as(c_int, room.unk2) != args[0]) return 1;
    return 2;
}
