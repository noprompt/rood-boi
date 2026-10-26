//! zig_diff spec: func_8008DD0C -> func_8008DD0C.func_8008DD0C (146C.c).
//! Inputs: the room's collision map is an arena object or null (its width and
//! height any i16, including negative ones, so the unsigned compare with
//! `(u_int)width` matters), with the two coordinates chosen to be inside the
//! map, exactly at its edge (`>> 7` equal to the limit), beyond it, or at
//! extreme and negative values. The callee's result is drawn from `ret_pick`
//! (set by prepare, so the unk4 equality `temp_v1 == 0` is reachable) or from
//! ctx.value, and it may rewrite the map's unk4, which the C re-reads.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008DD0C));

pub const classes = [_][:0]const u8{ "no-map", "arg0-out", "arg1-out", "inside-temp-nonpositive", "inside-temp-positive" };

/// The value the callee returns when the stub picks it (set by prepare, the
/// same in both runs).
var ret_pick: u8 = 0;

fn coord(ctx: *zd.Ctx, limit: i16) c_int {
    const lim: c_int = limit;
    return switch (ctx.range(u8, 0, 7)) {
        // inside the map: arg >> 7 < limit (unsigned)
        0...3 => ctx.range(c_int, 0, @max(lim, 1) * 128 - 1),
        // exactly at the edge: arg >> 7 == limit (the C's `<` sees EQUAL sides)
        4 => lim * 128 + ctx.range(c_int, 0, 127),
        // beyond the map
        5 => (lim + 1) * 128 + ctx.range(c_int, 0, 127),
        // extremes, negatives, the sign bit
        else => ctx.pick(c_int, &.{ -1, -128, -129, 0x7FFF_FFFF, -0x8000_0000, 0, 127, 128 }),
    };
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const map = ctx.alloc(v._mpdRoomCollisionMapSection);
    map.width = ctx.pick(i16, &.{ 0, 1, 2, 3, -1, 32767, -32768 });
    map.height = ctx.pick(i16, &.{ 0, 1, 2, 3, -1, 32767, -32768 });
    map.unk4 = ctx.pick(i16, &.{ 0, 1, 254, 255, -1, 32767, -32768 });
    ret_pick = ctx.pick(u8, &.{ 0, 1, 0x7F, 0x80, 0xFF });
    // Make `temp_v1 == 0` happen: unk4 exactly 2 * (ret & 0x7F).
    if (ctx.chance(3)) map.unk4 = @intCast(2 * @as(i16, ret_pick & 0x7F));
    psx.put(&room.collisionMapSection, if (ctx.chance(8)) null else map);
    const arg0 = coord(ctx, map.width);
    const arg1 = coord(ctx, map.height);
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    const room = v.g.vs_battle_roomData();
    const map = psx.get(room.collisionMapSection) orelse return 0;
    const a0: c_uint = @bitCast(args[0] >> 7);
    const w: c_uint = @bitCast(@as(c_int, map.width));
    if (a0 >= w) return 1;
    const b0: c_uint = @bitCast(args[1] >> 7);
    const h: c_uint = @bitCast(@as(c_int, map.height));
    if (b0 >= h) return 2;
    return if (map.unk4 > 254) 4 else 3;
}

pub const stubs = struct {
    pub fn func_80099514(ctx: *zd.Ctx, x: anytype, y: anytype, z: anytype) u8 {
        _ = x;
        _ = y;
        _ = z;
        // The callee may rewrite the collision map's unk4, which the C re-reads.
        if (ctx.value(u1) == 1) {
            const room = v.g.vs_battle_roomData();
            if (psx.get(room.collisionMapSection)) |m| m.unk4 = ctx.value(i16);
        }
        if (ctx.value(u1) == 1) return ret_pick;
        return ctx.value(u8);
    }
};
