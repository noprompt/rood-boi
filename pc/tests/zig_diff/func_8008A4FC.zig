//! zig_diff spec: func_8008A4FC -> func_8008A4FC.func_8008A4FC (146C.c).
//! Inputs: the scratch-path selector (bits 16-18 of the first callee's result,
//! with or without bit 31), the 0x504000 mask bits, the three sp10 bytes that
//! feed the room lookup, the room-header bit that `func_8008B764` returns
//! (a block filled 0xFE or 0xFF, so bit 0 is clear or set whatever the field's
//! position), and the room pointer (null, or a room whose unk6 is 16 or not).
//! The callees write sp10 and the block from prepared values, so every branch
//! of the C is chosen in prepare and the classes name the path taken.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
const c = @import("c_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008A4FC));

pub const classes = [_][:0]const u8{
    "scratch-path",
    "mask-set",
    "obj-bit-clear",
    "room-null",
    "room-not-16",
    "room-hit",
};

var g_t: u32 = 0;
var g_sp: [3]u8 = .{ 0, 0, 0 };
var g_fill: u8 = 0xFF;
var g_block: [*]u8 = undefined;
var g_room: *v._mpdRoomSection9 = undefined;
var g_room_null: bool = false;

pub fn prepare(ctx: *zd.Ctx) Args {
    var t: u32 = ctx.int(u32);
    t &= ~@as(u32, 0x70000 | 0x504000);
    if (ctx.chance(2)) t |= ctx.edge(u32, &.{ 0x10000, 0x20000, 0x40000, 0x70000 });
    if (!ctx.chance(3)) t |= ctx.edge(u32, &.{ 0x4000, 0x100000, 0x400000, 0x504000 });
    g_t = t;

    g_sp = .{ ctx.int(u8), ctx.int(u8), ctx.int(u8) };

    g_block = ctx.allocBytes(256, 16);
    g_fill = if (ctx.chance(2)) 0xFE else 0xFF;
    @memset(g_block[0..256], g_fill);

    g_room = ctx.alloc(v._mpdRoomSection9);
    g_room.unk6 = ctx.edge(i16, &.{ 16, 16, 15, 0, -1, 17 });
    g_room.unkA = ctx.int(u8);
    g_room_null = ctx.chance(3);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if ((g_t & 0x70000) != 0) return 0;
    if ((g_t & 0x504000) != 0) return 1;
    if (g_fill == 0xFE) return 2;
    if (g_room_null) return 3;
    if (g_room.unk6 != 16) return 4;
    return 5;
}

pub const stubs = struct {
    pub fn func_800A1108(ctx: *zd.Ctx, a: anytype, out: anytype) c_int {
        _ = a;
        const p: [*]u8 = @ptrCast(@alignCast(out));
        p[0] = g_sp[0];
        p[1] = g_sp[1];
        p[2] = g_sp[2];
        p[3] = ctx.value(u8);
        return ctx.value(c_int);
    }

    pub fn func_800A0BE0(ctx: *zd.Ctx, a: anytype) c_uint {
        _ = ctx;
        _ = a;
        return g_t;
    }

    pub fn func_8008B764(ctx: *zd.Ctx, a: anytype, b: anytype, d: anytype) ?*c._mpdRoomSection3 {
        _ = ctx;
        _ = a;
        _ = b;
        _ = d;
        return @ptrCast(g_block);
    }

    pub fn func_8008D438(ctx: *zd.Ctx, a: anytype, b: anytype, d: anytype) [*c]v._mpdRoomSection9 {
        _ = ctx;
        _ = a;
        _ = b;
        _ = d;
        if (g_room_null) return null;
        return @ptrCast(g_room);
    }
};
