//! zig_diff spec: func_80074950 -> func_80074950.func_80074950 (146C.c).
//! Inputs: an arbitrary arg0. Each iteration picks one scenario (the mode),
//! and the stubs follow it: no room (func_8008D508 returns NULL), a room whose
//! unk12 differs from the id (func_80074798's return), a room whose state flag
//! is set, a room whose vy misses the computed value, and a full match that
//! returns the room. The stubs write what the real callees write: func_800A1108
//! and func_80074798 fill the output struct and the id buffer, and func_8008DC7C
//! writes the vy the C compares, so the match path is reached often. Random
//! values cover signed chars, the sign bit of the 15-bit sign extension, and
//! unk10 + 0x3C0 wrapping to c_short.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80074950));

pub const classes = [_][:0]const u8{ "no-room", "id-mismatch", "flag-set", "vy-mismatch", "match" };

/// The scenario of this iteration, chosen by prepare; the stubs follow it.
var mode: usize = 0;
/// The output struct func_800A1108 was given, for func_8008DC7C to write.
var saved_sp: ?*v.func_8006EBF8_t = null;
/// The id func_80074798 returned, which the room's unk12 must match.
var last_s2: c_int = 0;

pub const stubs = struct {
    pub fn func_800A1108(ctx: *zd.Ctx, arg0: anytype, out: anytype) c_int {
        _ = arg0;
        const sp: *v.func_8006EBF8_t = @ptrCast(@alignCast(out.?));
        sp.unk0.unk4.vy = ctx.value(i16);
        saved_sp = sp;
        return ctx.value(c_int);
    }

    pub fn func_80074798(ctx: *zd.Ctx, sp: anytype, buf: anytype) c_int {
        const s: *v.func_8006EBF8_t = @ptrCast(@alignCast(sp.?));
        s.unk0.unk4.vx = ctx.value(i16);
        buf[0] = @bitCast(ctx.value(i8));
        buf[1] = @bitCast(ctx.value(i8));
        buf[2] = @bitCast(ctx.value(i8));
        last_s2 = ctx.value(i16);
        return last_s2;
    }

    pub fn func_8008D508(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype) ?*v._mpdRoomSection13 {
        _ = arg0;
        _ = arg1;
        _ = arg2;
        if (mode == 0) return null;
        const room = ctx.alloc(v._mpdRoomSection13);
        room.unk10 = ctx.value(i16);
        room.unk12 = @truncate(if (mode == 1) last_s2 +% 1 else last_s2);
        return room;
    }

    pub fn vs_battle_getStateFlag(ctx: *zd.Ctx, flag: anytype) u8 {
        _ = flag;
        if (mode != 2) return 0;
        const r = ctx.value(u8);
        return if (r == 0) 1 else r;
    }

    pub fn func_8008DC7C(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_short {
        _ = arg0;
        _ = arg1;
        const x = ctx.value(i16);
        if (saved_sp) |sp| {
            const y: i32 = (@as(i32, x) << 17) >> 17;
            const bump: i32 = if (mode == 3) 1 else 0;
            sp.unk0.unk4.vy = @intCast(y + 0x60 + bump);
        }
        return x;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    mode = ctx.range(usize, 0, 4);
    saved_sp = null;
    last_s2 = 0;
    return .{ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF, -0x8000, 0x10000 })};
}

pub fn classify(args: Args) usize {
    _ = args;
    return mode;
}
