//! zig_diff spec: func_8008DC7C -> func_8008DC7C.func_8008DC7C (146C.c).
//! Inputs: the room's collision map pointer is null (raw 0) or points at an
//! arena map with an i16 width and height (negative, zero, one, and the
//! extremes included). The x and y arguments are sometimes random ints,
//! sometimes in range, sometimes exactly at the bound `width * 128` (so
//! `arg >> 7` equals the width) or just below it. The callee func_80099514 is
//! a recording stub returning any u8, so every bit of its result reaches the
//! `& 0x7F` and `& 0x80` tests. It may also overwrite the map's unk4, which
//! the C reads after the call.
const std = @import("std");
const zd = @import("zdiff");
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008DC7C));

pub const classes = [_][:0]const u8{ "null-map", "x-out", "y-out", "in-range" };

/// The arena map the room points at (set by prepare; the stub writes it).
var coll: *v._mpdRoomCollisionMapSection = undefined;

pub const stubs = struct {
    pub fn func_80099514(ctx: *zd.Ctx, a: anytype, b: anytype, z: anytype) u8 {
        _ = a;
        _ = b;
        _ = z;
        if (ctx.value(u1) == 1) coll.unk4 = ctx.value(i16);
        return ctx.value(u8);
    }
};

fn axis(ctx: *zd.Ctx, n: c_int) c_int {
    if (ctx.chance(3)) return ctx.int(c_int);
    const top: c_int = @max(n, 1) * 128;
    if (ctx.chance(4)) return top;
    return ctx.range(c_int, -256, top + 255);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const map = ctx.alloc(v._mpdRoomCollisionMapSection);
    coll = map;
    map.width = ctx.pick(i16, &.{ 0, 1, 2, 8, -1, -32768, 32767 });
    map.height = ctx.pick(i16, &.{ 0, 1, 2, 8, -1, -32768, 32767 });
    map.unk4 = ctx.int(i16);
    psx.put(&room.collisionMapSection, if (ctx.chance(6)) null else map);

    const w: c_int = map.width;
    const h: c_int = map.height;
    const arg0 = axis(ctx, w);
    const arg1 = axis(ctx, h);
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    const room = v.g.vs_battle_roomData();
    if (psx.rawOf(room.collisionMapSection) == 0) return 0;
    const w: u32 = @bitCast(@as(i32, coll.width));
    const h: u32 = @bitCast(@as(i32, coll.height));
    const x: u32 = @bitCast(args[0] >> 7);
    const y: u32 = @bitCast(args[1] >> 7);
    if (x >= w) return 1;
    if (y >= h) return 2;
    return 3;
}
