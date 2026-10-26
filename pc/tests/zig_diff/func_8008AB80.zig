//! zig_diff spec: func_8008AB80 -> func_8008AB80.func_8008AB80 (146C.c).
//! Inputs: the room header's unk0 (1 about half the time, otherwise edge
//! values and random bytes), unk2 (edge values including negatives), and
//! arg0 equal to unk2 (sign-extended) about half the time, otherwise
//! unrelated edge values. This covers the unk0 != 1 short-circuit, the
//! unk2 != arg0 miss, and the matching hit that writes unk1 and returns 1.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008AB80));

pub const classes = [_][:0]const u8{ "not-one", "one-mismatch", "one-match" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    if (ctx.chance(2)) {
        room.unk0 = 1;
    } else {
        room.unk0 = ctx.pick(u8, &.{ 0, 2, 3, 127, 128, 255 });
    }
    room.unk2 = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 256, -256 });
    const arg0: c_int = if (ctx.chance(2))
        @as(c_int, room.unk2)
    else
        ctx.pick(c_int, &.{ 0, 1, -1, 32767, 32768, -32768, 65537, -65537 });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const room = v.g.vs_battle_roomData();
    if (room.unk0 != 1) return 0;
    return if (@as(c_int, room.unk2) == args[0]) 2 else 1;
}
