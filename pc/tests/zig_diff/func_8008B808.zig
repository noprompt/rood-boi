//! zig_diff spec: func_8008B808 -> func_8008B808.func_8008B808 (146C.c).
//! Inputs: the room's section3 array in a 16 KB arena block, its base in the
//! middle so negative indices stay inside the block, present or NULL; the
//! section12 array in a 4 KB block, present or NULL; a collision map whose
//! width and height come from a small set so the index stays in range. arg2
//! is mostly -4..20 with edges (2 most often, 1, 0, -1) and out-of-range
//! values that only reach the NULL paths; arg0 and arg1 are small; arg3 is
//! zero, positive, and negative (with the sign bit).
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B808));

pub const classes = [_][:0]const u8{ "no-section3", "section12-null", "section12-write", "section3-low-index" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();

    const sec3_blk = ctx.allocBytes(16384, 16);
    const sec3: *v._mpdRoomSection3 = @ptrCast(@alignCast(sec3_blk + 8192));
    const sec12_blk = ctx.allocBytes(4096, 16);
    const sec12: *v._mpdRoomSection12 = @ptrCast(@alignCast(sec12_blk));
    const map = ctx.alloc(v._mpdRoomCollisionMapSection);
    map.width = ctx.edge(i16, &.{ 0, 1, 2, 3, 8, 16, -1, -3 });
    map.height = ctx.edge(i16, &.{ 0, 1, 2, 3, 8, 16, -1, -3 });
    psx.put(&room.collisionMapSection, map);

    const arg2: c_int = if (ctx.chance(3))
        ctx.edge(c_int, &.{ 2, 2, 1, 0, -1, -4, 21, 2147483647, -2147483648 })
    else
        ctx.range(c_int, -4, 20);

    // Indices stay inside the blocks only for arg2 in -4..20; outside that
    // range the C must take a NULL path (section3 NULL below -4, section12
    // NULL above 20).
    const sec3_on = arg2 >= -4 and !ctx.chance(6);
    const sec12_on = arg2 >= 2 and arg2 <= 20 and !ctx.chance(4);
    psx.put(&room.section3, if (sec3_on) sec3 else null);
    psx.put(&room.section12, if (sec12_on) sec12 else null);

    const arg0 = ctx.range(c_int, -20, 20);
    const arg1 = ctx.range(c_int, -5, 5);
    const arg3 = ctx.edge(c_int, &.{ 0, 0, 1, 5, -1, -2147483648, 2147483647, 256 });

    return .{ arg0, arg1, arg2, arg3 };
}

pub fn classify(args: Args) usize {
    const room = v.g.vs_battle_roomData();
    if (psx.get(room.section3) == null) return 0;
    if (args[2] < 2) return 3;
    return if (psx.get(room.section12) == null) 1 else 2;
}
