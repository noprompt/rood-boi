//! zig_diff spec: func_8008D508 -> func_8008D508.func_8008D508 (146C.c).
//! Inputs: the room's section13 pointer either null or an arena array of
//! 0-12 entries (the length word is the entry count times the entry size
//! plus a random remainder under one entry, so the division truncates).
//! One entry is the target, which matches on unk0, unk2 and unk4 unless
//! the draw says otherwise. Other entries match on one, two or all three
//! fields, or stay random. The entry one past the end matches sometimes, so
//! a loop bound one too far is caught. Arguments are i16 edges and random
//! values; a tenth are wide c_ints whose low 16 bits equal an entry's field,
//! so a port that truncates the arguments would wrongly match.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008D508));

pub const classes = [_][:0]const u8{ "null-section", "empty", "wide-arg", "found", "partial", "missed" };

fn argValue(ctx: *zd.Ctx) c_int {
    if (ctx.chance(10)) return ctx.int(c_int);
    return @as(c_int, ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 7 }));
}

fn wide(x: c_int) bool {
    return x < std.math.minInt(i16) or x > std.math.maxInt(i16);
}

fn setMatch(e: *v._mpdRoomSection13, a0: c_int, a1: c_int, a2: c_int) void {
    e.unk0 = @truncate(a0);
    e.unk2 = @truncate(a1);
    e.unk4 = @truncate(a2);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const size = @sizeOf(v._mpdRoomSection13);
    const g = v.g.vs_battle_roomData();
    const n = ctx.range(usize, 0, 12);
    const a0 = argValue(ctx);
    const a1 = argValue(ctx);
    const a2 = argValue(ctx);

    // n + 1 entries: the extra one is past the end and must never be returned.
    const base: [*]v._mpdRoomSection13 = @ptrCast(@alignCast(ctx.allocBytes((n + 1) * size, 16)));
    const target: usize = if (n == 0) 0 else ctx.range(usize, 0, n - 1);

    var i: usize = 0;
    while (i <= n) : (i += 1) {
        const e = &base[i];
        if (i < n and i == target and !ctx.chance(3)) {
            setMatch(e, a0, a1, a2);
        } else if (i < n) {
            switch (ctx.range(u8, 0, 5)) {
                0 => e.unk0 = @truncate(a0),
                1 => {
                    e.unk0 = @truncate(a0);
                    e.unk2 = @truncate(a1);
                    e.unk4 = ctx.int(i16);
                },
                2 => e.unk2 = @truncate(a1),
                3 => e.unk4 = @truncate(a2),
                4 => setMatch(e, a0, a1, a2),
                else => {},
            }
        } else if (ctx.chance(3)) {
            setMatch(e, a0, a1, a2);
        }
    }

    const extra = ctx.range(u32, 0, size - 1);
    const len: u32 = @intCast(n * size + extra);
    if (ctx.chance(6)) {
        psx.put(&g.section13, null);
    } else {
        psx.put(&g.section13, &base[0]);
    }
    g.header.section13Len = len;

    return .{ a0, a1, a2 };
}

pub fn classify(args: Args) usize {
    const g = v.g.vs_battle_roomData();
    const p = psx.get(g.section13) orelse return 0;
    const size = @sizeOf(v._mpdRoomSection13);
    const count = g.header.section13Len / size;
    if (count == 0) return 1;
    const a0 = args[0];
    const a1 = args[1];
    const a2 = args[2];
    if (wide(a0) or wide(a1) or wide(a2)) return 2;
    const elems: [*]v._mpdRoomSection13 = @ptrCast(p);
    var partial = false;
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const e = &elems[i];
        if (@as(c_int, e.unk0) == a0 and @as(c_int, e.unk2) == a1) {
            if (@as(c_int, e.unk4) == a2) return 3;
            partial = true;
        }
    }
    return if (partial) 4 else 5;
}
