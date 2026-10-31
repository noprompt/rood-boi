//! zig_diff spec: func_8008E400 -> func_8008E400.func_8008E400 (146C.c).
//! Inputs: each state flag (unk20, unk40) zero or set, so the early return
//! fires on either one. The room's section9 pointer is either a live arena
//! block or a raw guest address drawn from edges with and without the sign
//! bit, including 0 (the null test). section9Len sits at the unsigned edges
//! 0x80000000 and 0xFFFFFFFF, where an unsigned and a signed /12 differ.
//! arg0 is always a live int, since the C stores through it.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E400));

pub const classes = [_][:0]const u8{ "flagged", "section9-null", "section9-set" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const flags = v.g.vs_main_stateFlags();
    flags.unk20 = if (ctx.chance(2)) 0 else ctx.pick(u8, &.{ 1, 0x80, 0xFF });
    flags.unk40 = if (ctx.chance(2)) 0 else ctx.pick(u8, &.{ 1, 0x80, 0xFF });

    const room = v.g.vs_battle_roomData();
    room.header.section9Len = ctx.pick(u32, &.{ 0, 11, 12, 13, 0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF });
    if (ctx.chance(2)) {
        psx.put(&room.section9, ctx.alloc(v._mpdRoomSection9));
    } else {
        const raw = ctx.pick(u32, &.{ 0, 1, 0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF });
        std.mem.writeInt(u32, @as(*[4]u8, @ptrCast(&room.section9)), raw, .little);
    }

    const arg0: [*c]c_int = @ptrCast(ctx.alloc(c_int));
    return .{arg0};
}

pub fn classify(args: Args) usize {
    _ = args;
    const flags = v.g.vs_main_stateFlags();
    if (flags.unk20 != 0 or flags.unk40 != 0) return 0;
    const room = v.g.vs_battle_roomData();
    const raw = std.mem.readInt(u32, @as(*[4]u8, @ptrCast(&room.section9)), .little);
    return if (raw == 0) 1 else 2;
}
