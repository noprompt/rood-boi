//! zig_diff spec: func_8008B2C0 -> func_8008B2C0.func_8008B2C0 (146C.c).
//! Inputs: vs_battle_roomData.unk0 is zero (the store is skipped), 1, 0x40,
//! 0x7F, 0x80 or 0xFF (nonzero, with and without the sign bit), and the
//! argument spans the values whose low byte the store keeps: 0, -1, 0x7F,
//! 0x80, 0x100 (low byte 0), INT_MIN and INT_MAX. The global is otherwise
//! random, so unk1 starts with an arbitrary value that a skipped store must keep.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B2C0));

pub const classes = [_][:0]const u8{ "flag-zero", "flag-nonzero", "flag-sign" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    room.unk0 = ctx.edge(u8, &.{ 0, 0, 1, 0x40, 0x7F, 0x80, 0xFF });
    const arg = ctx.pick(c_int, &.{ 0, -1, 0x7F, 0x80, 0x100, std.math.minInt(c_int), std.math.maxInt(c_int) });
    return .{arg};
}

pub fn classify(args: Args) usize {
    _ = args;
    const u = v.g.vs_battle_roomData().unk0;
    if (u == 0) return 0;
    return if ((u & 0x80) == 0) 1 else 2;
}
