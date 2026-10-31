//! zig_diff spec: func_8008C1C8 -> func_8008C1C8.func_8008C1C8 (146C.c).
//! Inputs: an arg0 section in the arena (an alias of the table element it
//! names about one time in four), with its lock byte, unkE (zero half the
//! time, with and without the sign bit) and unk10 (-1, or an index from -8 to
//! 7 into a 16-entry table the room global points at). The table entry's
//! unkA is zero or not, its unkE zero or not. func_80093764 is locked (nonzero,
//! sometimes negative) or unlocked (0); func_8008BD74 writes unkE, unk12 and
//! unk0.unkA of the section it is passed, as the real callee may.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008C1C8));

pub const classes = [_][:0]const u8{ "locked", "unlocked-no-table", "table-unmarked", "table-marked-set", "table-marked-zero" };

var table: [*]v._mpdRoomSectionA = undefined;
var locked: bool = false;

/// The element k places from base, for a signed k (C's `base[k]`).
fn elem(base: [*]v._mpdRoomSectionA, k: i16) *v._mpdRoomSectionA {
    const off: usize = @bitCast(@as(isize, k) * @sizeOf(v._mpdRoomSectionA));
    return @ptrFromInt(@intFromPtr(base) +% off);
}

pub const stubs = struct {
    pub fn func_80093764(ctx: *zd.Ctx, lock: anytype) c_int {
        _ = lock;
        if (!locked) return 0;
        const r = ctx.value(c_int);
        return if (r == 0) 0x100 else r;
    }

    pub fn func_8008BD74(ctx: *zd.Ctx, p: anytype) void {
        const a: *v._mpdRoomSectionA = @ptrCast(@alignCast(p));
        if (ctx.value(u1) == 1) a.unkE = ctx.value(i16);
        if (ctx.value(u1) == 1) a.unk12 = ctx.value(u8);
        if (ctx.value(u1) == 1) a.unk0.unkA = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const block: [*]v._mpdRoomSectionA = @ptrCast(@alignCast(ctx.allocBytes(16 * @sizeOf(v._mpdRoomSectionA), 16)));
    table = block + 8;
    psx.put(&v.g.vs_battle_roomData().sectionA, &table[0]);

    locked = ctx.chance(5);
    const idx: i16 = ctx.edge(i16, &.{ -1, -1, 0, 1, 2, -2, -8, 7, 3, -5 });

    if (idx != -1) {
        const t = elem(table, idx);
        t.unk0.unkA = ctx.edge(u8, &.{ 0, 0, 1, 0x80, 0xFF });
        t.unkE = ctx.edge(i16, &.{ 0, 0, 1, -1, -32768, 32767 });
        t.unk12 = ctx.int(u8);
    }

    const arg: *v._mpdRoomSectionA = if (idx != -1 and ctx.chance(4))
        elem(table, idx)
    else
        ctx.alloc(v._mpdRoomSectionA);
    arg.unk10 = idx;
    arg.unkE = ctx.edge(i16, &.{ 0, 0, 0, 1, -1, -32768 });
    arg.unk0.unk8.lock.unk1 = ctx.int(u8);
    return .{arg};
}

pub fn classify(args: Args) usize {
    if (locked) return 0;
    const a = args[0].?;
    if (a.unk10 == -1) return 1;
    const e = elem(table, a.unk10);
    if (e.unk0.unkA == 0) return 2;
    return if (e.unkE == 0) 4 else 3;
}
