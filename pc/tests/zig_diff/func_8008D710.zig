//! zig_diff spec: func_8008D710 -> func_8008D710.func_8008D710 (146C.c).
//! Inputs: vs_battle_roomData.section13 is either NULL or an arena array of
//! 0-4 section-13 records plus two spare slots, so the C's extra element
//! reads stay in memory the harness owns. section13Len is a whole number of
//! records plus a random remainder, so the integer division truncates. Each
//! record has random i16 fields (negative unk0 and unk4 included). The
//! func_8008B764 stub returns NULL about 40% of the time, otherwise a slot of a
//! pool of section-3 objects the C writes through. vs_battle_getStateFlag
//! returns 0 or a byte with its top bit set. func_80093824 may rewrite a
//! record's unk10, which the C reads on later iterations.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008D710));

pub const classes = [_][:0]const u8{ "null-section", "empty", "one-element", "several" };

/// The record array prepare built (read by the stubs).
var cur: [*]v._mpdRoomSection13 = undefined;
var cur_n: usize = 0;
/// Section-3 objects func_8008B764 hands out.
var pool: [*]v._mpdRoomSection3 = undefined;

pub const stubs = struct {
    pub fn func_8008B764(ctx: *zd.Ctx, a0: anytype, a1: anytype, a2: anytype) ?*v._mpdRoomSection3 {
        _ = a0;
        _ = a1;
        _ = a2;
        if (ctx.value(u8) < 100) return null;
        return &pool[ctx.calls % 8];
    }

    pub fn vs_battle_getStateFlag(ctx: *zd.Ctx, flag: anytype) u8 {
        _ = flag;
        const x = ctx.value(u8);
        return if (x < 96) 0 else x;
    }

    pub fn func_80093824(ctx: *zd.Ctx, flag: anytype) void {
        _ = flag;
        if (cur_n != 0 and ctx.value(u1) == 1) {
            const i = @as(usize, ctx.value(u8)) % cur_n;
            cur[i].unk10 = ctx.value(i16);
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const sz = @sizeOf(v._mpdRoomSection13);
    const n = ctx.range(usize, 0, 4);
    const r = ctx.range(usize, 0, sz - 1);
    room.header.section13Len = @intCast(n * sz + r);
    cur_n = n;
    const arr: [*]v._mpdRoomSection13 = @ptrCast(@alignCast(ctx.allocBytes(sz * (n + 2), 16)));
    cur = arr;
    pool = @ptrCast(@alignCast(ctx.allocBytes(@sizeOf(v._mpdRoomSection3) * 8, 16)));
    if (ctx.chance(8)) {
        psx.put(&room.section13, @as(?*v._mpdRoomSection13, null));
    } else {
        psx.put(&room.section13, &arr[0]);
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const room = v.g.vs_battle_roomData();
    _ = psx.get(room.section13) orelse return 0;
    const n = room.header.section13Len / @sizeOf(v._mpdRoomSection13);
    if (n == 0) return 1;
    if (n == 1) return 2;
    return 3;
}
