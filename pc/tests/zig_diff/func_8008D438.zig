//! zig_diff spec: func_8008D438 -> func_8008D438.func_8008D438 (146C.c).
//! Inputs: the room's section 9 pointer is null, or points at an arena table of
//! 10 records. The section9Len count is 0-8 elements (with a remainder under one
//! element). Records are 0 / +-1 / extreme i16 values, and unk6 is biased to 16 so
//! the `< 16` test sees equal sides. Matches are copied from a random record, and
//! records past the count are decoys carrying the same args, so an off-by-one loop
//! bound reads one. A past-end case has every in-count record differ from the args
//! while the decoy at the first index past the count matches, so only a loop that
//! reads past the count returns a pointer. The two state flags are each zero or
//! nonzero with and without the sign bit, so the `||` short-circuit is covered.
//! Classes: null section, no elements, no match, match returned, match filtered
//! (flags set, unk6 < 16), match kept by the flags (unk6 >= 16).
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008D438));

pub const classes = [_][:0]const u8{
    "null-section",
    "no-elements",
    "no-match",
    "match-kept",
    "match-filtered",
    "match-filter-passed",
};

const N = 10;
const elem = @sizeOf(v._mpdRoomSection9);

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const flags = v.g.vs_main_stateFlags();

    const e16 = [_]i16{ 0, 1, -1, 32767, -32768 };
    const e6 = [_]i16{ -1, 0, 15, 16, 17, 32767, -32768 };
    const fl = [_]u8{ 1, 0x7F, 0x80, 0xFF };
    const ints = [_]c_int{ 0, 1, -1, 32767, -32768, 65536 };

    flags.unk20 = if (ctx.chance(2)) 0 else ctx.pick(u8, &fl);
    flags.unk40 = if (ctx.chance(2)) 0 else ctx.pick(u8, &fl);

    const mode = ctx.range(u8, 0, 11);

    if (mode == 0) {
        const none: ?*v._mpdRoomSection9 = null;
        psx.put(&room.section9, none);
        room.header.section9Len = ctx.int(u32);
        return .{ ctx.pick(c_int, &ints), ctx.pick(c_int, &ints), ctx.pick(c_int, &ints) };
    }

    const first: *v._mpdRoomSection9 = @ptrCast(@alignCast(ctx.allocBytes(N * elem, 16)));
    const recs: [*]v._mpdRoomSection9 = @ptrCast(first);
    for (0..N) |i| {
        const r = &recs[i];
        r.unk0 = ctx.pick(i16, &e16);
        r.unk2 = ctx.pick(i16, &e16);
        r.unk4 = ctx.pick(i16, &e16);
        r.unk6 = ctx.pick(i16, &e6);
    }
    psx.put(&room.section9, first);

    if (mode == 1) {
        // No elements: section9Len is under one element.
        room.header.section9Len = ctx.range(u32, 0, elem - 1);
        return .{ ctx.pick(c_int, &ints), ctx.pick(c_int, &ints), ctx.pick(c_int, &ints) };
    }

    const count: usize = ctx.range(usize, 1, 8);
    room.header.section9Len = @intCast(count * elem + ctx.range(usize, 0, elem - 1));

    if (mode == 2) {
        // Large args: no record can match.
        return .{
            ctx.range(c_int, 40000, 0x7fff_ffff),
            ctx.range(c_int, 40000, 0x7fff_ffff),
            ctx.range(c_int, 40000, 0x7fff_ffff),
        };
    }

    if (mode == 3) {
        // Past-end match: in-count records never match, the first decoy does.
        var i: usize = 0;
        while (i < count) : (i += 1) recs[i].unk0 = 0;
        while (i < N) : (i += 1) {
            recs[i].unk0 = 1000;
            recs[i].unk2 = 2000;
            recs[i].unk4 = 3000;
        }
        return .{ 1000, 2000, 3000 };
    }

    // Match from a random in-count record; past-count decoys match the same args.
    const t = ctx.range(usize, 0, count - 1);
    if (ctx.chance(2)) recs[t].unk6 = 16;
    const a = [3]c_int{ @as(c_int, recs[t].unk0), @as(c_int, recs[t].unk2), @as(c_int, recs[t].unk4) };
    var i: usize = count;
    while (i < N) : (i += 1) {
        recs[i].unk0 = @intCast(a[0]);
        recs[i].unk2 = @intCast(a[1]);
        recs[i].unk4 = @intCast(a[2]);
    }
    return .{ a[0], a[1], a[2] };
}

pub fn classify(args: Args) usize {
    const room = v.g.vs_battle_roomData();
    const first = psx.get(room.section9) orelse return 0;
    const base: [*]v._mpdRoomSection9 = @ptrCast(first);
    const n: usize = room.header.section9Len / elem;
    if (n == 0) return 1;
    const fl = v.g.vs_main_stateFlags();
    var i: usize = 0;
    while (i < n) : (i += 1) {
        const r = &base[i];
        if (@as(c_int, r.unk0) != args[0] or @as(c_int, r.unk2) != args[1] or @as(c_int, r.unk4) != args[2]) continue;
        if (fl.unk20 == 0 and fl.unk40 == 0) return 3;
        return if (r.unk6 < 16) 4 else 5;
    }
    return 2;
}
