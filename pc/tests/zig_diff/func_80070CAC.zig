//! zig_diff spec: func_80070CAC -> func_80070CAC.func_80070CAC (146C.c).
//! Inputs: a random D_800F19CC_t in the arena, reached through the global
//! pointer, with action 93, 241 (the room loop), 79 (the points loop), or
//! another value. The room table is 8 arena entries with unk0/unk2 at the
//! i16 edges and unk6 at 15, 16, 17 or 0, so the `!= 16` test goes both
//! ways. func_8008E400 writes a count in -8..7 (negative counts skip the loop).
//! func_8008D2C0 returns -1, or 0..4 with that many points filled (4 is the
//! most the C's local array holds). func_8008DC7C returns any i16. The void
//! callee func_8007087C may rewrite the action it was handed.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80070CAC));

pub const classes = [_][:0]const u8{ "rooms", "points", "other" };

var room_base: [*]v._mpdRoomSection9 = undefined;

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;
    d.unk8.actionIndex = ctx.edge(u16, &.{ 93, 241, 79, 0, 94, 0xFFFF });

    const rooms = ctx.allocBytes(8 * @sizeOf(v._mpdRoomSection9), 16);
    room_base = @ptrCast(@alignCast(rooms));
    for (0..8) |i| {
        const r = &room_base[i];
        r.unk0 = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
        r.unk2 = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
        r.unk6 = ctx.edge(i16, &.{ 15, 16, 17, 0 });
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return switch (v.g.D_800F19CC().*.?.unk8.actionIndex) {
        93, 241 => 0,
        79 => 1,
        else => 2,
    };
}

pub const stubs = struct {
    pub fn func_8008E400(ctx: *zd.Ctx, count: anytype) [*c]v._mpdRoomSection9 {
        count.* = ctx.value(i4);
        return room_base;
    }

    pub fn func_8008D2C0(ctx: *zd.Ctx, points: anytype) c_int {
        if (ctx.value(u8) < 32) return -1;
        const n: c_int = ctx.value(u8) % 5;
        var i: c_int = 0;
        while (i < n) : (i += 1) {
            points[@intCast(i)].unk0 = ctx.value(i16);
            points[@intCast(i)].unk1 = ctx.value(i16);
            points[@intCast(i)].unk2 = ctx.value(i16);
        }
        return n;
    }

    pub fn func_8008DC7C(ctx: *zd.Ctx, a: anytype, b: anytype) i16 {
        _ = a;
        _ = b;
        return ctx.value(i16);
    }

    pub fn func_8007087C(ctx: *zd.Ctx, p: anytype) void {
        const d: *v.D_800F19CC_t = @ptrCast(@alignCast(p));
        if (ctx.value(u1) == 1) d.unk8.actionIndex = ctx.value(u16);
    }
};
