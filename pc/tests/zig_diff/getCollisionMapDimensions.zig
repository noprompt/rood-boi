//! zig_diff spec: _getCollisionMapDimensions -> get_collision_map_dimensions.getCollisionMapDimensions (146C.c).
//! Inputs: the room's collisionMapSection either null (the C's NULL guard) or
//! pointing at an arena section with random bytes and a random height and
//! width. The width and height edges cover negative values, the 4095/4096
//! boundary where width*16 leaves 16 bits, and 2048..4095, where bit 15 of
//! the u_short part is set. The argument is unused.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getCollisionMapDimensions));

pub const classes = [_][:0]const u8{ "null", "negative-height", "wide-width", "normal" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const sec = ctx.alloc(v._mpdRoomCollisionMapSection);
    sec.width = ctx.pick(i16, &.{ 0, 1, -1, 2047, 2048, 4095, 4096, 32767, -32768 });
    sec.height = ctx.pick(i16, &.{ 0, 1, -1, 0x7FFF, -32768, 255 });
    psx.put(&room.collisionMapSection, if (ctx.chance(5)) null else sec);
    return .{ctx.int(c_int)};
}

pub fn classify(args: Args) usize {
    _ = args;
    const room = v.g.vs_battle_roomData();
    const p = psx.get(room.collisionMapSection) orelse return 0;
    if (p.height < 0) return 1;
    if (p.width < 0 or p.width > 4095) return 2;
    return 3;
}
