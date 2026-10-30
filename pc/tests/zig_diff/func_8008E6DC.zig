//! zig_diff spec: func_8008E6DC -> func_8008E6DC.func_8008E6DC (146C.c).
//! Inputs: an index arg0 in 0..6 into the 8-entry range table D_800E849C, with
//! start and end sometimes equal and sometimes end < start, so the loop is
//! skipped; a battle scene in the arena whose first room carries a zoneId and
//! mapId in 0..3 (or any i16); and the 32-byte head of D_800E84AC (four bytes
//! per row, rows 0..7) filled with values 0..3, so rows match the room at
//! random: by the first clause, by the second, or by neither.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E6DC));

pub const classes = [_][:0]const u8{ "no-loop", "match-first-clause", "match-second-clause", "no-match" };

fn tableBytes() [*]u8 {
    return psx.globalMany(u8, "D_800E84AC");
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.range(c_int, 0, 6);
    const d = v.g.D_800E849C();
    const start = ctx.range(i16, 0, 7);
    const end: i16 = if (ctx.chance(4)) start else ctx.range(i16, 0, 8);
    d[@intCast(arg0)] = start;
    d[@intCast(arg0 + 1)] = end;

    const t = tableBytes();
    for (0..32) |k| t[k] = ctx.range(u8, 0, 3);

    const raw = ctx.allocBytes(4 + 2 * @sizeOf(v.vs_battle_room), 16);
    const scene: *v.vs_battle_scene = @ptrCast(@alignCast(raw));
    scene.roomCount = 1;
    const room: *v.vs_battle_room = @ptrFromInt(@intFromPtr(raw) + 4);
    room.zoneId = if (ctx.chance(16)) ctx.int(i16) else ctx.range(i16, 0, 3);
    room.mapId = if (ctx.chance(16)) ctx.int(i16) else ctx.range(i16, 0, 3);
    psx.put(&v.g.vs_battle_roomData().sectionF, scene);

    return .{arg0};
}

pub fn classify(args: Args) usize {
    const arg0: usize = @intCast(args[0]);
    const d = v.g.D_800E849C();
    const start: i32 = d[arg0];
    const end: i32 = d[arg0 + 1];
    if (start >= end) return 0;

    const rd = v.g.vs_battle_roomData();
    const room = psx.byteAt(v.vs_battle_room, psx.get(rd.sectionF), 4);
    const zone: i32 = room.zoneId;
    const map: i32 = room.mapId;

    const t = tableBytes();
    var i = start;
    while (i < end) : (i += 1) {
        const r: usize = @intCast(i * 4);
        if (@as(i32, t[r]) == zone and @as(i32, t[r + 1]) == map) return 1;
        if (@as(i32, t[r + 2]) == zone and @as(i32, t[r + 3]) == map) return 2;
    }
    return 3;
}
