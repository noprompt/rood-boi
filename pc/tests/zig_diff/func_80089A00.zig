//! zig_diff spec: func_80089A00 -> func_80089A00.func_80089A00 (146C.c).
//! Inputs: the four D_80061078 slots (unk0 from a small set so the minimum
//! search and the decrement loop see ties, 200 for the sign bit, 0 for
//! inactive), with zndId/mapId matching the zone context about half the time.
//! The zone context uses edges (-1, 256 and 65536 never match a u8/u16 slot),
//! and the enemy list has 0-8 entries (the arena block holds 8). In some runs
//! one slot is forced to match. func_80069E80 returns null or a 4-byte probe
//! in the arena whose byte 1 it writes, so the C reads back a stub-written
//! value. vs_main_bzero zeroes its destination as the real one does.
//! The enemy list pointer is null one run in eight (and then no record is found by
//! func_80069E80): the C never dereferences it, so the port must not either.
//! Classes: a slot matches the zone (hit) or none does (miss).
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80089A00));

pub const classes = [_][:0]const u8{ "hit", "miss" };

var probe: [*]u8 = undefined;
/// The enemy list pointer is null this iteration (the C only dereferences it when func_80069E80 finds a record).
var list_null: bool = false;

/// The low byte of an i32 as a u8 (wrapping, like the C's narrowing store).
fn low8(x: i32) u8 {
    return @truncate(@as(u32, @bitCast(x)));
}

/// The low 16 bits of an i32 as a u16.
fn low16(x: i32) u16 {
    return @truncate(@as(u32, @bitCast(x)));
}

pub const stubs = struct {
    pub fn func_80069E80(ctx: *zd.Ctx, i: anytype) [*c]u8 {
        _ = i;
        if (ctx.value(u8) < 96 or list_null) return null;
        probe[1] = ctx.value(u8);
        return probe;
    }

    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const raw = if (@typeInfo(@TypeOf(p)) == .optional) p.? else p;
        const b: [*]u8 = @ptrCast(raw);
        @memset(b[0..@intCast(n)], 0);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const zc = v.g._zoneContext();
    const tbl = v.g.D_80061078();
    const arr = ctx.alloc([8]v._mpdEnemy);
    probe = ctx.allocBytes(4, 1);
    psx.put(&zc.mpdEnemies, &arr[0]);
    list_null = ctx.chance(8);
    if (list_null) psx.put(&zc.mpdEnemies, @as(?*v._mpdEnemy, null));
    zc.mpdEnemyCount = ctx.edge(u32, &.{ 0, 1, 2, 3, 5, 8 });

    const forced = ctx.chance(2);
    zc.zndId = if (forced) ctx.edge(i32, &.{ 0, 1, 2, 255 }) else ctx.edge(i32, &.{ 0, 1, 2, 255, -1, 256 });
    zc.mapId = if (forced) ctx.edge(i32, &.{ 0, 1, 7, 65535 }) else ctx.edge(i32, &.{ 0, 1, 7, 65535, 65536, -1 });

    for (tbl) |*e| {
        e.unk0 = ctx.edge(u8, &.{ 0, 1, 2, 3, 4, 5, 200 });
        if (ctx.chance(2)) {
            e.zndId = low8(zc.zndId);
        } else {
            e.zndId = ctx.int(u8);
        }
        if (ctx.chance(2)) {
            e.mapId = low16(zc.mapId);
        } else {
            e.mapId = ctx.int(u16);
        }
    }

    if (forced) {
        const k = ctx.range(usize, 0, 3);
        tbl[k].unk0 = ctx.edge(u8, &.{ 1, 2, 3, 200 });
        tbl[k].zndId = low8(zc.zndId);
        tbl[k].mapId = low16(zc.mapId);
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const zc = v.g._zoneContext();
    for (v.g.D_80061078().*) |e| {
        if (e.unk0 != 0 and @as(i32, e.zndId) == zc.zndId and @as(i32, e.mapId) == zc.mapId) return 0;
    }
    return 1;
}
