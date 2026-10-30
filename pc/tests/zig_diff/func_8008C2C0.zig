//! zig_diff spec: func_8008C2C0 -> func_8008C2C0.func_8008C2C0 (146C.c).
//! Inputs: the room's section 11 is null, empty, or a short list of entries laid
//! out as the C walks them (a 4-byte header, unk2 data bytes, padding to 4).
//! The target entry matches the four arguments, or misses on exactly one of them
//! (arg0 and arg1 with high bits set, the two 1-bit fields, or the v field), or
//! the length cuts the list short, or nothing matches. The camera yaw gives every
//! v in 0..7, with edges around the 0x900 bias and negative angles. func_8008C40C
//! may rewrite the camera yaw and the section length the C reads after it;
//! func_80091AC0 may shrink the matched entry's unk2 while the C walks it.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008C2C0));

pub const classes = [_][:0]const u8{
    "null-section",
    "no-entries",
    "match",
    "miss-arg0",
    "miss-arg1",
    "miss-arg2",
    "miss-arg3",
    "miss-v",
    "no-match",
    "short-len",
};

/// The entry the C should match (set by prepare, read by the stubs).
var target: ?*v._mpdRoomSection11 = null;
/// The input class prepare built (returned by classify).
var class_of: usize = 0;

const Fields = struct { k0: u5, k5: u5, k10: u1, k11: u3, k14: u1 };

fn entrySize(dlen: u16) usize {
    return 4 + @as(usize, dlen) + ((4 - (dlen & 3)) & 3);
}

fn buildEntry(ctx: *zd.Ctx, f: Fields, dlen: u16) *v._mpdRoomSection11 {
    const e: *v._mpdRoomSection11 = @ptrCast(@alignCast(ctx.allocBytes(entrySize(dlen), 4)));
    e.unk2 = dlen;
    psx.setBits(e, "unk0_0", f.k0);
    psx.setBits(e, "unk0_5", f.k5);
    psx.setBits(e, "unk0_10", f.k10);
    psx.setBits(e, "unk0_11", f.k11);
    psx.setBits(e, "unk0_14", f.k14);
    return e;
}

pub const stubs = struct {
    pub fn func_8008C40C(ctx: *zd.Ctx) void {
        // The C reads the camera yaw and the section length after this call.
        if (ctx.value(u2) == 0) {
            v.g.vs_scratch().camera.angles.vy = @as(i32, @bitCast(ctx.value(u32))) >> 2;
        }
        if (ctx.value(u2) == 0) {
            v.g.vs_battle_roomData().header.section11Len = ctx.value(u8);
        }
    }

    pub fn func_80091AC0(ctx: *zd.Ctx, x: anytype) void {
        _ = x;
        // The callee may shrink the entry the C is walking (its unk2 is re-read).
        if (target) |t| {
            if (ctx.value(u2) == 0) {
                t.unk2 = ctx.value(u8) & 3;
            }
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = v.g.vs_battle_roomData();
    const s = v.g.vs_scratch();
    target = null;

    s.camera.angles.vy = if (ctx.chance(3))
        ctx.edge(i32, &.{ 0, -1, -0x900, 0x7FFF_F600, -0x8000_0000 })
    else
        ctx.int(i32) >> 1;
    const vsel: u3 = @intCast(((@as(u32, @bitCast(s.camera.angles.vy)) +% 0x900) & 0xFFF) >> 9);

    const roll = ctx.range(u8, 0, 99);
    const cls: usize = if (roll < 8) 0 else if (roll < 18) 1 else if (roll < 50) 2 else if (roll < 58) 3 else if (roll < 64) 4 else if (roll < 70) 5 else if (roll < 76) 6 else if (roll < 84) 7 else if (roll < 92) 8 else 9;
    class_of = cls;

    if (cls == 0) {
        psx.put(&d.section11, null);
        d.header.section11Len = ctx.int(u32);
        return .{ ctx.int(c_int), ctx.int(c_int), ctx.int(c_int), ctx.int(c_int) };
    }
    if (cls == 1) {
        psx.put(&d.section11, ctx.alloc(v._mpdRoomSection11));
        d.header.section11Len = 0;
        return .{ ctx.int(c_int), ctx.int(c_int), ctx.int(c_int), ctx.int(c_int) };
    }

    const n: usize = ctx.range(usize, 1, 4);
    const t: usize = ctx.range(usize, 0, n - 1);
    var ents: [4]*v._mpdRoomSection11 = undefined;
    var total: u32 = 0;
    var args: [4]c_int = undefined;

    for (0..n) |i| {
        const dlen = ctx.edge(u16, &.{ 0, 1, 2, 3, 4, 5, 7, 8, 9 });
        var f = Fields{
            .k0 = ctx.int(u5),
            .k5 = ctx.int(u5),
            .k10 = ctx.int(u1),
            .k11 = ctx.int(u3),
            .k14 = ctx.int(u1),
        };
        if (i == t) {
            f.k11 = vsel;
            args = .{ @as(c_int, f.k0), @as(c_int, f.k5), @as(c_int, f.k10), @as(c_int, f.k14) };
            switch (cls) {
                3 => {
                    args[0] = if (ctx.chance(2)) args[0] + 32 else @as(c_int, f.k0 ^ 1);
                },
                4 => {
                    args[1] = if (ctx.chance(2)) args[1] + 32 else @as(c_int, f.k5 ^ 1);
                },
                5 => {
                    args[2] = @as(c_int, f.k10 ^ 1);
                },
                6 => {
                    args[3] = @as(c_int, f.k14 ^ 1);
                },
                7 => {
                    f.k11 = vsel +% 1;
                },
                else => {},
            }
        }
        const e = buildEntry(ctx, f, dlen);
        ents[i] = e;
        if (i == t) target = e;
        total += @intCast(entrySize(dlen));
    }

    if (cls == 8) {
        args = .{ ctx.int(c_int), ctx.int(c_int), ctx.int(c_int), ctx.int(c_int) };
        target = null;
    }

    psx.put(&d.section11, ents[0]);
    d.header.section11Len = if (cls == 9) total - 4 else total;
    return .{ args[0], args[1], args[2], args[3] };
}

pub fn classify(args: Args) usize {
    _ = args;
    return class_of;
}
