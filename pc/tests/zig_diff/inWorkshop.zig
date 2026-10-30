//! zig_diff spec: vs_battle_inWorkshop -> in_workshop.inWorkshop (146C.c).
//! Inputs: the room's sectionB points at an arena block whose isWorkshop is 0
//! or a byte from {1, 0x7F, 0x80, 0xFF}, so a signed read or a mask shows.
//! sectionA points at a second block with random bytes, so a read through the
//! wrong section pointer differs from the right one.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").inWorkshop));

pub const classes = [_][:0]const u8{ "workshop", "not-workshop" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const sec = ctx.alloc(v._mpdRoomSectionB);
    const other = ctx.alloc(v._mpdRoomSectionB);
    psx.put(&room.sectionB, sec);
    psx.put(&room.sectionA, other);
    sec.isWorkshop = if (ctx.chance(2)) 0 else ctx.pick(u8, &.{ 1, 0x7F, 0x80, 0xFF });
    other.isWorkshop = ctx.int(u8);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const sec = psx.get(v.g.vs_battle_roomData().sectionB).?;
    return if (sec.isWorkshop == 0) 1 else 0;
}
