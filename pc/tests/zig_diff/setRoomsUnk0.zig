//! zig_diff spec: vs_battle_setRoomsUnk0 -> set_rooms_unk0.setRoomsUnk0 (146C.c).
//! Inputs: a scene in the arena with roomCount -2..8 (no rooms, one room,
//! several rooms). The arena holds one slot past roomCount so a loop bound
//! that runs one room too far reads defined memory. Zone and map ids sit on
//! edges (map 0 makes map - 1 negative). The C never tests the scene
//! pointer, so it is never null. The _getLocationId stub returns 0 (the
//! `> 0` branch's equal side), a negative id, or 1..512 (the roomFlags word
//! indices 0..16 the C can read). It sometimes rewrites a roomFlags word,
//! which the C reads back for later rooms: the callee can change a global
//! the C reads after the call.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setRoomsUnk0));

pub const classes = [_][:0]const u8{ "no-rooms", "one-room", "several-rooms" };

pub const stubs = struct {
    pub fn _getLocationId(ctx: *zd.Ctx, zone: anytype, map: anytype) c_int {
        _ = zone;
        _ = map;
        const r = ctx.value(u8);
        const id: c_int = if (r < 80)
            0
        else if (r < 120)
            -1 - @as(c_int, ctx.value(u8))
        else
            @as(c_int, ctx.value(u16) % 512) + 1;
        if (ctx.value(u8) < 24) {
            v.g.vs_main_mapStatus().roomFlags[ctx.value(u4)] = ctx.value(i32);
        }
        return id;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const n = ctx.edge(i32, &.{ -2, -1, 0, 1, 2, 3, 5, 8 });
    const count: usize = if (n > 0) @intCast(n) else 0;
    const bytes = ctx.allocBytes(4 + 12 * (count + 1), 16);
    const scene: *v.vs_battle_scene = @ptrCast(@alignCast(bytes));
    scene.roomCount = n;
    const rooms: [*]v.vs_battle_room = @ptrCast(&scene.rooms);
    for (0..count + 1) |i| {
        rooms[i].zoneId = ctx.pick(i16, &.{ 0, 1, 2, 3, -1, 32767 });
        rooms[i].mapId = ctx.pick(i16, &.{ 0, 1, 2, 17, 33, -1, 32767 });
    }
    return .{scene};
}

pub fn classify(args: Args) usize {
    const n = args[0].?.roomCount;
    if (n <= 0) return 0;
    if (n == 1) return 1;
    return 2;
}
