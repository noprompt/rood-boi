//! zig_diff spec: func_8008DEAC -> func_8008DEAC.func_8008DEAC (146C.c).
//! Inputs: either a section-9 record pointer (arg0 set, with any arg1 including
//! the u8 truncation edges), or a null arg0 with the room's section9 pointer
//! null, or pointing at an arena buffer holding 0-40 twelve-byte records (the
//! section9Len divided by 12, with remainders 0-11 and the count edges 0, 1, 2
//! and 40). The loop writes arg1 into every record's unkA. No callees.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008DEAC));

pub const classes = [_][:0]const u8{ "arg0-nonnull", "null-no-section9", "null-section9-empty", "null-section9-looped" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const obj = ctx.alloc(v._mpdRoomSection9);
    const arg1: c_int = ctx.pick(c_int, &.{ 0, 1, -1, 127, 128, 255, 256, std.math.minInt(c_int), std.math.maxInt(c_int) });

    // section9Len = 12 * count + rem, so the C's len / 12 is count.
    const count: u32 = if (ctx.chance(3)) ctx.edge(u32, &.{ 0, 1, 2, 40 }) else ctx.range(u32, 0, 40);
    const rem: u32 = if (ctx.chance(2)) 0 else ctx.range(u32, 0, 11);
    room.header.section9Len = count * 12 + rem;

    // Room for the largest count (40) plus slack.
    const buf: *v._mpdRoomSection9 = @ptrCast(@alignCast(ctx.allocBytes(12 * 41, 4)));

    const mode = ctx.range(u8, 0, 3);
    if (mode == 0) {
        // arg0 non-null: the section9 pointer is not read.
        psx.put(&room.section9, if (ctx.chance(2)) @as(?*v._mpdRoomSection9, null) else buf);
        return .{ obj, arg1 };
    }
    if (mode == 1) {
        psx.put(&room.section9, @as(?*v._mpdRoomSection9, null));
        return .{ @as(?*v._mpdRoomSection9, null), arg1 };
    }
    psx.put(&room.section9, buf);
    return .{ @as(?*v._mpdRoomSection9, null), arg1 };
}

pub fn classify(args: Args) usize {
    if (args[0] != null) return 0;
    const room = v.g.vs_battle_roomData();
    if (psx.get(room.section9) == null) return 1;
    return if (room.header.section9Len / 12 != 0) 3 else 2;
}
