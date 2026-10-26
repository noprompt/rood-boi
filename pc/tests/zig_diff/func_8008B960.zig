//! zig_diff spec: func_8008B960 -> func_8008B960.func_8008B960 (146C.c).
//! Inputs: the room's door section is either absent or an arena array of 0-6
//! door records (the length sometimes carries a partial trailing record). Each
//! door's id (unk0_10) equals arg2 half the time, and its geometry (unk0_0,
//! unk0_5) matches one of the 3x3 offsets around (arg0, arg1) half the time, so
//! the scan breaks on the id test, breaks on the geometry test, or runs out and
//! yields NULL. arg2 is 2 often (the `>= 2` edge), and arg0/arg1 sit near the
//! 1..32 range a 5-bit door coordinate can match. The memcpy and bzero stubs
//! really copy and clear, as their callees do.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B960));

pub const classes = [_][:0]const u8{
    "no-door-section",
    "no-doors",
    "break-on-id",
    "break-on-geometry",
    "not-found",
    "id-seen-no-geometry",
};

pub const stubs = struct {
    pub fn vs_main_memcpy(ctx: *zd.Ctx, dest: anytype, src: anytype, sz: anytype) void {
        _ = ctx;
        const dp: ?*anyopaque = dest;
        const sp: ?*const anyopaque = src;
        const n: usize = @as(usize, sz);
        const d: [*]u8 = @ptrCast(@alignCast(dp.?));
        const s: [*]const u8 = @ptrCast(@alignCast(sp.?));
        @memcpy(d[0..n], s[0..n]);
    }

    pub fn vs_main_bzero(ctx: *zd.Ctx, dest: anytype, n: anytype) void {
        _ = ctx;
        const dp: ?*anyopaque = dest;
        const len: usize = @as(usize, @intCast(n));
        const d: [*]u8 = @ptrCast(@alignCast(dp.?));
        @memset(d[0..len], 0);
    }
};

fn low5(x: i64) u5 {
    return @truncate(@as(u64, @bitCast(x)));
}

fn low3(x: c_int) u3 {
    return @truncate(@as(u32, @bitCast(x)));
}

fn geomMatch(d: *v._mpdRoomDoorSection2, arg0: c_int, arg1: c_int, j: i64) bool {
    const x: i64 = psx.getBits(d, "unk0_0");
    const y: i64 = psx.getBits(d, "unk0_5");
    const ex: i64 = @as(i64, arg0) - 1 + @rem(j, 3);
    const ey: i64 = @as(i64, arg1) - 1 + @divTrunc(j, 3);
    return x == ex and y == ey;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &.{ 0, 1, 2, 3, 4, 5, 9, 10, -1, 33 });
    const arg1 = ctx.pick(c_int, &.{ 0, 1, 2, 3, 4, 5, 9, 10, -1, 33 });
    const arg2 = ctx.pick(c_int, &.{ 0, 1, 2, 2, 2, 3, 7, 8, -1 });
    const room = v.g.vs_battle_roomData();

    if (ctx.chance(10)) {
        const none: ?*v._mpdRoomDoorSection_t = null;
        psx.put(&room.doorSection, none);
        room.header.doorSectionLen = ctx.int(u32);
        return .{ arg0, arg1, arg2 };
    }

    const n: u32 = ctx.range(u32, 0, 6);
    const len: u32 = 12 * n + (if (ctx.chance(4)) ctx.range(u32, 0, 11) else 0);
    room.header.doorSectionLen = len;

    const count: usize = @max(@as(usize, n), 1);
    const entries: [*]v._mpdRoomDoorSection_t = @ptrCast(@alignCast(
        ctx.allocBytes(count * @sizeOf(v._mpdRoomDoorSection_t), 4),
    ));
    psx.put(&room.doorSection, &entries[0]);

    var k: usize = 0;
    while (k < count) : (k += 1) {
        const e = &entries[k];
        const j: i64 = ctx.range(i64, 0, 9);
        var g0: u5 = ctx.int(u5);
        var g1: u5 = ctx.int(u5);
        if (ctx.chance(2)) {
            g0 = low5(@as(i64, arg0) - 1 + @rem(j, 3));
            g1 = low5(@as(i64, arg1) - 1 + @divTrunc(j, 3));
        }
        const id: u3 = if (ctx.chance(2)) low3(arg2) else ctx.int(u3);
        psx.setBits(&e.unk2, "unk0_0", g0);
        psx.setBits(&e.unk2, "unk0_5", g1);
        psx.setBits(&e.unk2, "unk0_10", id);
    }

    return .{ arg0, arg1, arg2 };
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    const arg1 = args[1];
    const arg2 = args[2];
    const room = v.g.vs_battle_roomData();
    const base = psx.get(room.doorSection) orelse return 0;
    const n: u32 = room.header.doorSectionLen / 12;
    if (n == 0) return 1;
    const arr: [*]v._mpdRoomDoorSection_t = @ptrCast(base);
    var idSeen = false;
    var k: u32 = 0;
    while (k < n) : (k += 1) {
        const e = &arr[k];
        const id: c_int = psx.getBits(&e.unk2, "unk0_10");
        if (arg2 >= 2 and id == arg2) return 2;
        if (id == arg2) {
            idSeen = true;
            var j: i64 = 0;
            while (j < 9) : (j += 1) {
                if (geomMatch(&e.unk2, arg0, arg1, j)) return 3;
            }
        }
    }
    return if (idSeen) 5 else 4;
}
