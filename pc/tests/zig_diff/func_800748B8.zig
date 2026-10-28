//! zig_diff spec: func_800748B8 -> func_800748B8.func_800748B8 (146C.c).
//! Inputs: the room the stub of func_8008BC04 returns (a fresh arena object, or
//! null). The stub of func_800A1108 writes sp10's vy: any i16 most of the time,
//! or one shrunk to +-8192 so the NULL test can land exactly on 127. The stub of
//! func_8008DC7C picks the value that makes the test's operand (after the 15-bit
//! sign extension, minus vy, plus 0x3F) take each side: exactly 127 (the >= edge),
//! inside [0, 126] (kept), negative (signed vs unsigned compare), above 127, or a
//! raw i16 whose bit 15 the sign extension must drop. `mode` (set by prepare)
//! selects the case and is the input class.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800748B8));

pub const classes = [_][:0]const u8{ "raw", "eq-127", "kept", "negative", "over" };

var mode: usize = 0;
var room: ?*v._mpdRoomSectionA = null;
var stash_vy: i16 = 0;

fn view(p: anytype) *v.func_8006EBF8_t {
    const q: ?*anyopaque = p;
    return @ptrCast(@alignCast(q.?));
}

pub const stubs = struct {
    // Fills the out-struct the C then reads (unk4.vy); remembers vy for func_8008DC7C.
    pub fn func_800A1108(ctx: *zd.Ctx, arg0: anytype, out: anytype) c_int {
        _ = arg0;
        const s = view(out);
        s.unk0.unk4.vx = ctx.value(i16);
        s.unk0.unk4.vy = if (ctx.value(u2) == 0) ctx.value(i16) else ctx.value(i16) >> 2;
        s.unk0.unk4.vz = ctx.value(i16);
        s.unkC = ctx.value(i32);
        stash_vy = s.unk0.unk4.vy;
        return ctx.value(c_int);
    }

    // Writes the four sp20 bytes the C reads back as s0[0..3].
    pub fn func_80074798(ctx: *zd.Ctx, sp: anytype, out: anytype) c_int {
        _ = sp;
        const b: [*]u8 = @ptrCast(out);
        for (0..4) |i| b[i] = ctx.value(u8);
        return ctx.value(c_int);
    }

    // Returns the room in the arena or null (the C does not test it, only returns it).
    pub fn func_8008BC04(ctx: *zd.Ctx, a: anytype, b: anytype, c2: anytype) ?*v._mpdRoomSectionA {
        _ = a;
        _ = b;
        _ = c2;
        if (ctx.value(u1) == 0) return null;
        return room;
    }

    // The value the C's NULL test sees: chosen so x = sext15(ret) - vy + 63 lands on each side.
    pub fn func_8008DC7C(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) i16 {
        _ = arg0;
        _ = arg1;
        if (mode == 0) return ctx.value(i16);
        const t: i32 = switch (mode) {
            1 => 127,
            2 => if (ctx.value(u1) == 0) 0 else 126,
            3 => if (ctx.value(u1) == 0) -1 else -20000,
            else => if (ctx.value(u1) == 0) 128 else 16000,
        };
        return @truncate(t + @as(i32, stash_vy) - 63);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    mode = ctx.range(usize, 0, 4);
    const r = ctx.alloc(v._mpdRoomSectionA);
    room = if (ctx.chance(4)) null else r;
    return .{ctx.int(c_int)};
}

pub fn classify(args: Args) usize {
    _ = args;
    return mode;
}
