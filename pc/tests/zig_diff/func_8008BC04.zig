//! zig_diff spec: func_8008BC04 -> func_8008BC04.func_8008BC04 (146C.c).
//! Inputs: vs_battle_roomData.sectionA is null or points at an arena table of
//! _mpdRoomSectionA entries; sectionALen gives 0-199 entries (sometimes with
//! a remainder below 20, sometimes a huge count whose first entry matches so
//! the scan returns at once). The first entry's unkA is zero in one mode.
//! Entries hold small coordinates and kinds 4-7 (plus 0, 8, -1). The three
//! arguments come from an entry with deltas -1/0/1, so each switch case and
//! each && term is taken, or from values no entry holds, or from the entry
//! just past the count. Some matches use i16 extremes so an i16 wrap in a
//! port's `+ 1` / `- 1` shows.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008BC04));

pub const classes = [_][:0]const u8{
    "null-section",
    "no-count",
    "empty",
    "past-end",
    "not-found",
    "huge-count",
    "entry-match",
};

const Entry = v._mpdRoomSectionA;
const max_entries = 200;

var mode: usize = 0;

fn coord(ctx: *zd.Ctx) i16 {
    if (ctx.chance(10)) return ctx.edge(i16, &.{ 32767, -32768 });
    return ctx.range(i16, -3, 3);
}

fn kindOf(ctx: *zd.Ctx) i16 {
    if (ctx.chance(3)) return ctx.int(i16);
    return ctx.edge(i16, &.{ 4, 5, 6, 7, 4, 5, 6, 7, 0, 8, -1 });
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const table: [*]Entry = @ptrCast(@alignCast(ctx.allocBytes(max_entries * @sizeOf(Entry), 16)));
    mode = ctx.range(usize, 0, classes.len - 1);

    var count: u32 = ctx.range(u32, 0, 40);
    if (ctx.chance(6)) count = ctx.range(u32, 41, 199);
    if (mode == 2) {
        count = 0;
    } else if (count == 0) {
        count = 1;
    }

    var len: u32 = 20 * count;
    if (ctx.chance(4)) len += ctx.range(u32, 1, 19);

    // Entries 0..count are filled; entry count is the one just past the scan.
    var k: u32 = 0;
    while (k <= count) : (k += 1) {
        const e = &table[k];
        e.unk0.unk0 = coord(ctx);
        e.unk0.unk2 = coord(ctx);
        e.unk0.unk4 = coord(ctx);
        e.unk0.unk6 = kindOf(ctx);
        e.unk0.unkA = ctx.range(u8, 1, 255);
    }

    room.header.sectionALen = len;
    if (mode == 0) {
        psx.put(&room.sectionA, @as(?*Entry, null));
    } else {
        psx.put(&room.sectionA, &table[0]);
    }

    if (mode == 1) table[0].unk0.unkA = 0;

    if (mode == 3) {
        table[count].unk0.unk0 = 100;
        table[count].unk0.unk2 = 100;
        table[count].unk0.unk4 = 100;
        table[count].unk0.unk6 = 4;
        table[count].unk0.unkA = 1;
    }

    if (mode == 5) {
        len = ctx.range(u32, 0x8000_0000, 0xFFFF_FFFF);
        room.header.sectionALen = len;
    }

    var a = [3]c_int{ 0, 0, 0 };
    if (mode == 3) {
        a = .{ 100, 100, 100 };
    } else if (mode == 4) {
        a = .{ 100, 101, 102 };
    } else if (mode == 0 or mode == 2) {
        a = .{
            ctx.range(c_int, -3, 3),
            ctx.range(c_int, -3, 3),
            ctx.range(c_int, -3, 3),
        };
    } else {
        const t: u32 = if (mode == 5) 0 else ctx.range(u32, 0, count - 1);
        const e = &table[t];
        const d = if (mode == 5)
            [3]c_int{ 0, 0, 0 }
        else
            [3]c_int{
                ctx.edge(c_int, &.{ -1, 0, 0, 1 }),
                ctx.edge(c_int, &.{ -1, 0, 0, 1 }),
                ctx.edge(c_int, &.{ -1, 0, 0, 1 }),
            };
        a = .{
            @as(c_int, e.unk0.unk0) + d[0],
            @as(c_int, e.unk0.unk2) + d[1],
            @as(c_int, e.unk0.unk4) + d[2],
        };
        // i16 wrap edges: kind 5 with x = 32767 and arg0 = -32768, or kind 7
        // with x = -32768 and arg0 = 32767 (the C promotes to int, no wrap).
        if (mode == 6 and ctx.chance(8)) {
            if (ctx.chance(2)) {
                e.unk0.unk6 = 5;
                e.unk0.unk0 = 32767;
                a[0] = -32768;
            } else {
                e.unk0.unk6 = 7;
                e.unk0.unk0 = -32768;
                a[0] = 32767;
            }
            a[1] = @as(c_int, e.unk0.unk2);
            a[2] = @as(c_int, e.unk0.unk4);
        }
    }

    return .{ a[0], a[1], a[2] };
}

pub fn classify(args: Args) usize {
    _ = args;
    return mode;
}
