//! zig_diff spec: func_8007C654 -> func_8007C654.func_8007C654 (146C.c).
//! Inputs: the door section is either null or an arena object (its bytes are
//! random), and the two integers are edge values or any i32. The C has no
//! branches. Its value flow is the out-parameter of func_800A1108, which the
//! stub fills with random bytes, and the three bytes the C reads back from it
//! for func_8008B960. func_8007C5C0 and func_800A1108 return random ints the C
//! ignores.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C654));

pub const classes = [_][:0]const u8{ "null-door", "door" };

pub const stubs = struct {
    pub fn func_8007C5C0(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) c_int {
        _ = a;
        _ = b;
        _ = c;
        return ctx.value(c_int);
    }

    pub fn func_800A1108(ctx: *zd.Ctx, id: anytype, out: anytype) c_int {
        _ = id;
        // The C reads back the bytes this call writes into its out-parameter
        // (the 16-byte func_8006EBF8_t), so fill all of them.
        const bytes: [*]u8 = @ptrCast(@alignCast(out.?));
        for (0..16) |i| bytes[i] = ctx.value(u8);
        return ctx.value(c_int);
    }

    pub fn func_8008B960(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) void {
        _ = ctx;
        _ = a;
        _ = b;
        _ = c;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const door: ?*v._mpdRoomDoorSection_t = if (ctx.chance(4))
        null
    else
        @ptrCast(ctx.alloc(v._mpdRoomDoorSection_t));
    const arg1 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000, 256 });
    const arg2 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000, 256 });
    return .{ door, arg1, arg2 };
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}
